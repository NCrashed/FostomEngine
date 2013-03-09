//          Copyright Gushcha Anton, Shamyan Roman 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
module util.net.clSocketManager;

import
	util.iprotocol;// temporaly solution
	
import 
	std.stdio,
	std.stream,
	std.socket,
	core.time,
	core.thread;

static this()
{
	nc = new InternetAddress("95.31.28.217",10100);
	localhost = new InternetAddress("localhost", 10100);
}

InternetAddress localhost;
InternetAddress nc;
	
void connect(InternetAddress ia)
{
	Socket sock;
	try
	{
		sock = new TcpSocket(ia);
	}
	catch (Exception e)
	{
		writeln("Cannot connect to:",sock.remoteAddress().toString());
		return;
	}
	
	debug
	{
		writeln("Connected");
	}
	auto buf1 = constructMessage!Bmsg(10,"Hello Server Wolrd");
	auto buf2 = constructMessage!Cmsg(1005001010,"Hi Server Wolrd");
	
	//Hello
	auto buf = buf1;
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));

	
	//Hello + Hi
	buf = buf1 ~ buf2;
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));

	
	//Hi
	buf = buf2[0..$/2];
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));
	buf = buf2[$/2..$];
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));	
	
	
	buf = buf1~buf2[0..$/2];
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));
	
	
	buf = buf2[$/2..$];
	sock.send(buf);
	writeln("Sended");
	Thread.sleep(dur!"msecs"(1000));		
	
	writeln("Finished");
	sock.close();	
}