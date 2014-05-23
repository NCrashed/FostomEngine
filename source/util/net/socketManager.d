//          Copyright Gushcha Anton, Shamyan Roman 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
module util.net.socketManager;

import 
	std.stdio,
	std.socket,
	std.stream,
	std.concurrency,
	core.time,
	std.conv,
	std.array;
	
import 
	util.iprotocol,
	util.protocol;

private enum PORT = 10100;

private enum MAX_LISTENS = 100;

private enum MAX_CONNECTIONS = 1000;

private enum _REMOVE_CONN = "rmcnn";

public enum MAX_BUF_SIZE = 1024;

void listen()
{
	Socket listener = new TcpSocket;
	listener.bind(new InternetAddress(PORT));
	
	listener.listen(MAX_LISTENS);
	
	int count = 0;
	
	Tid[] connections = new Tid[0];
	
	for(;count <= MAX_CONNECTIONS;)
	{
		Socket sn;
		try
		{
			sn = listener.accept();
		}
		catch (SocketAcceptException e) {}
		
		connections ~= spawn(&readingThread, thisTid, cast (shared Socket) sn);
		
		count++;
		
		void removeConnect(Tid tid)
		{
			foreach (size_t i; 0..connections.length - 1)
				if (connections[i] == tid)
				{
					connections = connections[0..i]~connections[i + 1..$];
				}
		}
		
		if (receiveTimeout(dur!"msecs"(10),
				(string msg, Tid tid) {if (msg == _REMOVE_CONN) removeConnect(tid);}))
		{
			count--;
		}
			
	}
}
/*
void managerThread(Tid owner, shared Socket sn)
{
	Socket sock = cast(Socket) sn;
	
}
*/

void readingThread(Tid owner, shared Socket sn)
{
	Socket sock = cast (Socket) sn;
	
	bool needed = true;
	
	ubyte[MAX_BUF_SIZE] buf;
	
	ubyte[] addtBuf;
	
	int _reads, _rest;
	
	
	bool flag = false;
	
	while (needed)
	{
		sock.blocking = true;
		string _socketAddress = sock.remoteAddress().toString();
		auto reads = sock.receive(buf);
		debug{
			writefln("\nReceived %d from %s",reads,_socketAddress);
		}
		
		if ((0 == reads)||(Socket.ERROR == reads))
		{
			owner.send(_REMOVE_CONN, thisTid);
			debug{
				writeln("Lost connection from:",_socketAddress);
			}
			try
			{
				sock.close();
			}
			catch (Exception e) {}
			return;
		}
			
		
		PMessage[] msgs = new PMessage[0];
		
		auto actualBuf = buf[0..reads];
		
		if ((_rest > 0)&&(reads < _rest))
			flag = false;
			
		if (flag)
		{
			//writeln("flagged");
			//writeln("buf",buf);
			//writeln("\nreaded:",actualBuf);
			//writeln("\naddt:",addtBuf);
			actualBuf = addtBuf ~ actualBuf;
			flag = false;
			//writeln(actualBuf.length);
			//writeln(actualBuf);
			
		}
		
		//writeln("\nreceived:",actualBuf);
		
		
		auto count = readObjects(actualBuf, msgs, _reads, _rest);
		
		writefln("Count %d sumreads %d rest %d",count,_reads,_rest);
		
		if (count == 0)
		{
			if (_rest > 0)
			{
				flag = true;
				if (addtBuf != null)
					addtBuf.clear();
				else
					addtBuf = new ubyte[0];
				
				addtBuf = actualBuf.dup;
				
				continue;
			}
			else
			{
				debug{
					writeln("Cannot understand msg from:",_socketAddress);
				}
			}
		}
		else
		{
			if ((_rest > 0) && (_reads > 0))
			{
				flag = true;
				if (addtBuf != null)
					addtBuf.clear();
				else
					addtBuf = new ubyte[0];
					
				addtBuf = actualBuf[_reads..$].dup;
			}
		}
		
		foreach (Msg; msgs)
		{
			Msg();
		}
		
		buf.clear();
		actualBuf.clear();
		
	}
}

/*
void writingThread(Tid owner, shared Socket sn)
{
	Socket sock = cast(Socket) sn;
	
	string address = sock.remoteAddress().toString();
	
	//waiting buffer for writing
	auto msg = receiveOnly!ubyte[]();
	
	if (msg.size > MAX_BUF_SIZE) 
	{
		debug{
			writeln("Too long buffer size:",msg.size);
			return;
		}
	}
	
	int writes;
	try
	{
		writes = sock.send(msg);
	}
	catch (Exception e)
	{
		debug{
			writeln("(Maybe) Socket Send exception",
				e.msg);
		}
			
	}
	
	if ((0==writes)||(Socket.ERROR == writes))	
	{
		owner.send(_REMOVE_CONN, thisTid);
		debug{
			writeln("Lost connection from:",address);
		}
	}
}
*/
