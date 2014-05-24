// written in the D programming language
/*
*   This file is part of FostomEngine.
*   
*   FostomEngine is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*   
*   FostomEngine is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*   
*   You should have received a copy of the GNU General Public License
*   along with FostomEngine.  If not, see <http://www.gnu.org/licenses/>.
*/
/**
*   Copyright: © 2013-2014 Anton Gushcha, Shamyan Roman
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Shamyan Roman,
*            Anton Gushcha <ncrashed@gmail.com>      
*/
module util.net.socket;

import std.stdio, std.socket, std.socketstream, std.stream;


class ConnectEx: Exception
{	
	private enum MSG = "Connection Error";
	this()
	{
		super(MSG);
	}
}

/// This class incapsulate general type Socket Listener
public class Listener 
{
	this()
	{
		socketList = new Socket[0];
	}

	enum PORT = 10100;

	enum BUF_SIZE = 1024; 

	private auto MAX_CONNECTIONS = 60u;

	///getter & setter of MAX_CONNECTIONS

	public uint getMaxConnections()
	{
		return MAX_CONNECTIONS;
	}

	public void setMaxConnections(uint max)
	{
		MAX_CONNECTIONS = max;
	}

	/// Socket List
	private Socket[] socketList; //accepted sockets

	/// SocketSet
	private SocketSet sSet; //all sockets

	/// Start listening
	private void run()
	{
		/// Setting listener port
	    Socket listener = new TcpSocket;
	    assert(listener.isAlive);
	    listener.blocking = false;
	    listener.bind(new InternetAddress(PORT)); /// todo: add choise to NetCard
	    listener.listen(10); /// notice: 10 is a good choice

	    sSet = new SocketSet(MAX_CONNECTIONS + 1);

	    for(;; sSet.reset() )
	    {
	    	//add incoming socket
	    	sSet.add(listener);

	    	//add previous iteration sockets
	    	foreach(Socket sock; socketList)
	    	{
	    		sSet.add(sock);
	    	}

	    	//wait some changes for sockets
	    	Socket.select(sSet, null, null); /// notice: maybe not null, null ?

	    	int i;

	    	void sock_down()
	    	{
	    		socketList[i].close();
	    		if (i != socketList.length - 1)
	    			socketList[i] = socketList[$ - 1];

	    		//todo 
	    		writefln("\tTotal connections: %d", socketList.length);

	    		//next();

	    	}

	    	void next()
	    	{

	    	}

    		//цикл учета 
	    	for (i = 0;; i++)
	    	{
		//next:
				if (i == socketList.length)
					break;

				////////////////////////////////////
				if (sSet.isSet(socketList[i]))
				{
					ubyte[BUF_SIZE] buf;

					int read = cast(int)socketList[i].receive(buf);

					if (Socket.ERROR == read)
					{
						throw new ConnectEx();
					}
					else if ( 0 == read )
					{
						try
						{
							//if the connection closed due to an error, remoteAddress() could fail
							//todo 
							writefln("Connection from %s closed.", socketList[i].remoteAddress().toString());
						}
						catch (SocketException)
						{
							//todo
							writeln("Connection closed.");						
						}
					}
				}
				////////////////////////////////////////////////////

				if (sSet.isSet(listener))
				{
					Socket sn;
					//try
					//{
						if(socketList.length < MAX_CONNECTIONS)
						{
							sn = listener.accept();
							//todo
							writefln("Connection from %s established.", sn.remoteAddress().toString());
							assert(sn.isAlive);
							assert(listener.isAlive);

							socketList ~= sn;
							//todo
							writefln("\tTotal connections: %d", socketList.length);
						}
					//}
				}

				
	    	}

	    }



	}

	/// add new socket to the socket list
	/**
	* Return -1 if success 
	*/
	private int add (Socket socket) 
	{
		try
		{
			socketList ~= socket;
			return -1;
		}
		catch (Exception ex)
		{
			throw new Exception("Socket adding exception");
			return 0;
		}
		
	}

	/// remove last added socket
	private int remove()
	{
		socketList = socketList[0..$ -1];
		return  -1;
	}
}

/// Implenets sockets by server
public class ServerSocket
{
	private Socket svSocket;

	private Stream ss;

	this(InternetAddress ia)
	{
		svSocket = new TcpSocket();
		writeln("===========\nSERVER\n=============");
		svSocket.bind(ia);
		svSocket.listen(10);
		
	}

	public void print()
	{
		svSocket = svSocket.accept();
		ss = new SocketStream(svSocket);
		write("Server: ");
		auto line = ss.readLine();
		import std.array;
		assert (line.length != 0);
		writeln(line);
	}

	@property Stream stream()
	{
		return ss;
	}

	@property Socket socket()
	{
		return svSocket;
	}

}


/// Implements socket by client
public class ClientSocket
{
	private Socket clSocket;

	private Stream ss;

	this(InternetAddress ia)
	{
		clSocket = new TcpSocket();
		writeln("===========\nCLIENT\n=============");
		clSocket.connect(ia);
		ss = new SocketStream(clSocket);

	}

	void write()
	{
		//string temp = "bebebe";
		//clSocket.send(temp);
		ss.writeString("10500");
	}

	@property Stream stream()
	{
		return ss;
	}

	@property Socket socket()
	{
		return clSocket;
	}
}
