#define _WIN32_WINNT 0x0500
 #include <windows.h>
#include <psapi.h>
#include <stdio.h>

char buf[1000];
LPVOID p;
PROCESS_INFORMATION pi;
STARTUPINFO si;

int memorylimit;
int timelimit;
ULONGLONG systemtimestart, systemtimeend;

ULONGLONG reltime()
{
        SYSTEMTIME st;
		GetSystemTime(&st);
		ULARGE_INTEGER t2;
		SystemTimeToFileTime(&st,(LPFILETIME)&t2);
		t2.QuadPart=t2.QuadPart/10/1000/100;   //  sec/10
		return t2.QuadPart;
}

bool bThreadStarted=false;
bool bNowTerminateTimer=false;

bool exception_handling = true;

DWORD WINAPI TimerThreadFunc( LPVOID lpParam ) 
{
	ResumeThread(pi.hThread);

	while(1){
        systemtimeend = reltime();
        bThreadStarted=true;
		if(bNowTerminateTimer) return 0;
        
/*		if( (timelimit*2*10 + 2000)/1000 < systemtimeend - systemtimestart )
		{
//			printf("SIGN1");
			break;
		}*/

		PROCESS_MEMORY_COUNTERS pmc;
		GetProcessMemoryInfo(pi.hProcess,&pmc,sizeof(pmc));
		if( pmc.PeakPagefileUsage > (unsigned)memorylimit*1024 ) break;

		FILETIME t1;
		ULARGE_INTEGER uu;
		GetProcessTimes(pi.hProcess,&t1,&t1,&t1,(FILETIME*)&uu);
		//printf("user time: %d\n",uu.LowPart);
		int remains = timelimit - uu.LowPart/10000 + ( timelimit / 1000 );
		//printf("remains : %d\n",remains);
		if(remains>0) Sleep(remains+10);
		else break;
	}

	TerminateProcess(pi.hProcess,13);
	return 0;
}

void shift(int &argc, char *argv[]) {
	int i;
	for (i = 1; i < argc; ++i) {
		argv[i-1] = argv[i];
	}
	--argc;
}

int main(int argc,char *argv[])
{
	if(argc<4)
	{
		printf("WinKill v. 2.7\n");
		printf("usage : %s <timelimit,sec|ms> <memorylimit,kb> <exename> <args>\n",argv[0]);
		printf("returns: 0 - ok\n"
			   "         1 - run-time error( nonzero exit code )\n"
			   "         2 - process time limit exceeded \n"
			   "         3 - memory limit exceeded\n"
			   "         4 - deadlock ( system time limit exceeded )\n"
			   "\n");

		
		return 1;
	}

	if (0 == strcmp("-java", argv[1])) {
		printf("-java option is deprecated, DO NOT USE.\n");
		exception_handling = false;
		shift(argc, argv);
	}

	timelimit=0;
	sscanf(argv[1],"%d",&timelimit);
	if(timelimit==0) { printf("wrong time limit\n"); return 1; }
        if (timelimit<61) timelimit*=1000;

	memorylimit=0;
	sscanf(argv[2],"%d",&memorylimit);
	if(memorylimit==0) { printf("wrong memory limit\n"); return 1; }

	memset( &si,0,sizeof(si));
    si.cb = sizeof(si);
    memset( &pi,0,sizeof(pi));

	int r;


	LPTSTR procargs=(LPTSTR)malloc(10000*sizeof(char));
	procargs[0]=0;
	for(int i=3;i<argc;i++) 
	{
	   strcat(procargs,"\"");
	   strcat(procargs,argv[i]);
	   strcat(procargs,"\" ");
	}

	SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
	BOOL cp = CreateProcess(NULL,procargs,NULL,NULL,FALSE,
		CREATE_SUSPENDED // | DEBUG_PROCESS | DEBUG_ONLY_THIS_PROCESS 
		, NULL,NULL,&si, &pi );
	if(!cp) { printf("cannot create process %s",argv[3]); return 1; }

	SECURITY_ATTRIBUTES sa=
		{sizeof(SECURITY_ATTRIBUTES),NULL,FALSE};
	HANDLE job = CreateJobObject(&sa,"winkill25");
	if(job==NULL) { printf("cannot create job object"); return 1; }

	JOBOBJECT_EXTENDED_LIMIT_INFORMATION extlimit={
		{ 
			{timelimit * 10/**1000*/*1000,0 },
			{0,0},//{3 * 10*1000*1000,0},
		  //JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION
		   JOB_OBJECT_LIMIT_PROCESS_MEMORY |
		   JOB_OBJECT_LIMIT_PROCESS_TIME
		  //| JOB_OBJECT_LIMIT_JOB_TIME
		  //| JOB_OBJECT_LIMIT_JOB_MEMORY
		  ,0,0,0,0,0,0 
		}
		// version 2.1 , { 0,0,0,0,0,0 }, (memorylimit+(memorylimit>>1))*1024, 0, 0,0 };
		, { 0,0,0,0,0,0 }, max( (memorylimit+(memorylimit>>1))*1024, 256*1024*1024) , 0, 0,0 };

	r=SetInformationJobObject(job,JobObjectExtendedLimitInformation,&extlimit,sizeof(extlimit));
	if(r==0) { printf("cannot set extended limit information to job object"); return 1; }

	JOBOBJECT_BASIC_UI_RESTRICTIONS uilimit={
		JOB_OBJECT_UILIMIT_DESKTOP
		| JOB_OBJECT_UILIMIT_DISPLAYSETTINGS
		| JOB_OBJECT_UILIMIT_EXITWINDOWS
		| JOB_OBJECT_UILIMIT_GLOBALATOMS
		| JOB_OBJECT_UILIMIT_HANDLES
		| JOB_OBJECT_UILIMIT_READCLIPBOARD
		| JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS
		| JOB_OBJECT_UILIMIT_WRITECLIPBOARD
	};

	r=SetInformationJobObject(job,JobObjectBasicUIRestrictions
		,&uilimit,sizeof(uilimit));
	if(r==0) { printf("cannot set UI restrictions to job object"); return 1; }

	r=AssignProcessToJobObject(job,pi.hProcess);
	if(r==0) { printf("cannot assign process %s to job object",argv[3]); return 1; }

	DEBUG_EVENT DebugEv;
	DWORD dwContinueStatus = DBG_CONTINUE;

	DWORD dwThreadId, dwThrdParam = 1;
	HANDLE hThread = CreateThread(NULL,0,TimerThreadFunc, 
        NULL, CREATE_SUSPENDED , NULL);

	if(hThread==NULL)
	{ printf("cannot create timer thread\n"); return 1; }

	systemtimestart=reltime();

	printf("starting...");
	fflush(stdin);

	ResumeThread(hThread);
//	while( ! bThreadStarted ) Sleep(0);
//	ResumeThread(pi.hThread);

	int bad=0;

#if 0
	for(;;) 
	{ 
		WaitForDebugEvent(&DebugEv, INFINITE); 
		printf("Debug event %d\n", DebugEv.dwDebugEventCode);
		switch (DebugEv.dwDebugEventCode) 
		{ 
				case EXCEPTION_DEBUG_EVENT: 
					if( DebugEv.u.Exception.ExceptionRecord.ExceptionCode == EXCEPTION_BREAKPOINT )
					{
						printf("Exception breakpoint\n");
					}else{
						printf("Exception # %d\n",DebugEv.u.Exception.ExceptionRecord.ExceptionCode);
						dwContinueStatus = DBG_EXCEPTION_NOT_HANDLED;
						if (exception_handling) bad=1;
					}
					break;
		 
				case CREATE_THREAD_DEBUG_EVENT: 
					//printf("Thread created H=%p\n",DebugEv.u.CreateThread.hThread );
					break;
		 
				case CREATE_PROCESS_DEBUG_EVENT: 
					//printf("Process created H=%p\n",DebugEv.u.CreateProcessInfo.hProcess );
					break;
		 
				case EXIT_THREAD_DEBUG_EVENT: 
					printf("Thread exited PID=%d TID=%d ExitCode=%d\n"
						, DebugEv.dwProcessId, DebugEv.dwThreadId , DebugEv.u.ExitThread.dwExitCode );
					break;
		 
				case EXIT_PROCESS_DEBUG_EVENT:
					//printf("Process exited PID=%d  ExitCode=%d\n"
					//	,DebugEv.dwProcessId,DebugEv.u.ExitProcess.dwExitCode);
					goto stopdebugging;
		 
				case LOAD_DLL_DEBUG_EVENT:
					//printf("Loading DLL : PID=%d TID=%d\n"
					//	, DebugEv.dwProcessId, DebugEv.dwThreadId );
					break;
		 
				case UNLOAD_DLL_DEBUG_EVENT: 
					//printf("Unloading DLL : PID=%d TID=%d\n"
					//	, DebugEv.dwProcessId, DebugEv.dwThreadId );
					break;

				case OUTPUT_DEBUG_STRING_EVENT: 
					break;
		} 
		 
		ContinueDebugEvent(DebugEv.dwProcessId, 
			DebugEv.dwThreadId, dwContinueStatus); 
	} 
#else
	if (WaitForSingleObject(pi.hProcess, INFINITE) != WAIT_OBJECT_0) {
		printf("Failed to wait for process termination.\n");
	}
		
#endif

stopdebugging:

	printf(" ...done\n");

	PROCESS_MEMORY_COUNTERS pmc;
	GetProcessMemoryInfo(pi.hProcess,&pmc,sizeof(pmc));
	printf("memory usage peak: %dkb ; ",pmc.PeakPagefileUsage/1024);
	int memusage=(int)pmc.PeakPagefileUsage;

// version 2.1 //////
/*	JOBOBJECT_EXTENDED_LIMIT_INFORMATION query;
	DWORD dr;
	QueryInformationJobObject(job,JobObjectExtendedLimitInformation
		,&query,sizeof(query),&dr);

	printf("\nmemory usage peak (job version): %d; \n",query.PeakProcessMemoryUsed);
*/////////////////////

	FILETIME t1;
	ULARGE_INTEGER uu;
	GetProcessTimes(pi.hProcess,&t1,&t1,&t1,(FILETIME*)&uu);
	printf(" user time: %d.%d sec ; ",uu.LowPart/1000/1000/10,(uu.LowPart/1000/1000)%10);
	int usertime=uu.LowPart;

	DWORD exitcode;
	GetExitCodeProcess(pi.hProcess,&exitcode);
	printf(" exit code: %d\n",exitcode);

	CloseHandle(pi.hThread);
	CloseHandle(pi.hProcess);
	CloseHandle(job);

	/*if( (timelimit*2*10+2000)/1000 < systemtimeend - systemtimestart )
	{
		printf("system time : %d.%d sec\n", (systemtimeend - systemtimestart)/10
			                               , (systemtimeend - systemtimestart)%10); //yeah, wrong
		printf("(4) DEADLOCK : SYSTEM TIME LIMIT EXCEEDED\n");
	        return 4;
	}*/

	if(memusage > memorylimit*1024)
	{
		printf("(3) MEMORY LIMIT EXCEEDED\n");
		return 3;
	}

	if(usertime > timelimit/**1000*/*1000*10)
	{
		printf("(2) TIME LIMIT EXCEEDED\n");
	        return 2;
	}

	if(exitcode!=0)
	{
		printf("(1) NONZERO EXIT CODE");
		bad=1;
	}

	if(bad) { printf("\n"); return 1; }

	printf("(0) OK\n");
	return 0;
}
