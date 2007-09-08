def get_local_ip
  IPSocket.getaddress(Socket.gethostname)
end
