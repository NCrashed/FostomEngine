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