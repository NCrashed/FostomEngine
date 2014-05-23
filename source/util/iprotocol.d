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
*   Copyright: © 2012-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*/
module util.iprotocol;

//import sockManager = util.net.sockManager;
import util.protocol;
import util.serialization.serializer;
import util.log;

import std.stdio;
import std.stream;
import std.traits;
import std.stream;

// Subj
mixin ProtocolPool!(int, BinaryArchive,
	0, Amsg,
	1, Bmsg,
	2, Cmsg);

private void foo(){};

ubyte[] writeObject(T)(T object)
{
	static assert(is(T:PMessage), "undefined Message. "~T.stringof~" must inherit PMessage.");
	
	ubyte[] buf;
	Stream stream;
	try
	{
		stream = serialize!BinaryArchive(object);
	}
	catch(Exception e)
	{	
		debug {
			string message = moduleName!foo;
			message ~= ":(Maybe) Serialize exception: ";
			//writeLog(message, LOG_ERROR_LEVEL.NOTICE, sockManager.LOG_NAME);
			writeln(message~e.msg);
		}
		return new ubyte[0];
	}

	//stream = constructMessage!Amsg(10, "Hello World!");

	Stream t = new MemoryStream;

	t.write(stream.size);

	t.copyFrom(stream);

	buf = new ubyte[cast(size_t) t.size()];

	t.read(buf);

	return buf;

}


int readObjects(ubyte[] buf, out PMessage[] objects, out int sumReads, out int rest)
{
	sumReads = 0;
	rest = 0;
	int res = 0;
	
	Stream stream = new MemoryStream(buf);

	while (!stream.eof)
	{
		
		ulong msgSize;
		try
		{
			stream.read(msgSize);
		}
		catch (ReadException e)
		{
			debug {
				writeln("ReadException: "~e.msg);
			}
			return -1;
		}
		
		if (msgSize > util.net.socketManager.MAX_BUF_SIZE)
		{
			debug{
				writeln("Too big size msg");
			}
			return res;
		}

		int id;
		stream.read(id);
		ubyte[] msg;
		
		msg = new ubyte[cast(size_t)msgSize];

		auto reads = stream.read(msg);
		

		if (reads < msgSize)
		{
			//rest = cast(int) stream.size -(reads + id.sizeof + msgSize.sizeof);
			rest = cast(int)(msgSize - reads);
			return res;
		}

		sumReads += reads + id.sizeof + msgSize.sizeof;
		rest = cast(int)(stream.size - sumReads);

		
		debug 
		{
			//writeln("Getted message id is ",id);	
		}

		try
		{
			Stream str = new MemoryStream(msg);
			str.position = 0;
			auto message = dispatchMessage!(deserialize)(id, str, "MSG");
			if (res == 0)
				objects = new PMessage[0];

			objects ~= message;
			res++;
		}
		catch (Exception e)
		{
			debug {
				string message = moduleName!writeObject;
				message ~= ":(Maybe) Deserialize exception:";
				writeln(message~e.msg);
			}
		}
	
	}
	return res;
}

class Amsg : PMessage
{
	int a;
	string name;

	this() {}

	this(int pa, string pb)
	{
		a = pa;
		name = pb;
	}

	void opCall()
	{
		writeln("AMsg call with ", a, " ",name);
	}
}

class Bmsg : PMessage
{
	int a;
	string name;

	this() {}

	this(int pa, string pb)
	{
		a = pa;
		name = pb;
	}

	void opCall()
	{
		writeln("BMsg call with ", a, " ",name);
	}
}

class Cmsg : PMessage
{
	int a;
	string name;

	this() {}

	this(int pa, string pb)
	{
		a = pa;
		name = pb;
	}

	void opCall()
	{
		writeln("CMsg call with ", a, " ",name);
	}
}

/*
unittest {
	//auto buf = writeObject(msg1);

	auto buf1 = constructMessage!Bmsg(10,"Hello Wolrd");
	auto buf2 = constructMessage!Cmsg(1005001010,"Hi Wolrd");
	//auto buf = buf1~buf2;
	auto buf = buf1[0..$/2];
	auto addBuf = buf1[$/2..$] ~ buf2;
	//writeln(buf);
	writeln("buf size:",buf.length);
	//writeln(buf);

	PMessage[] msgs;
//
	int a,b;

	auto count = readObjects(buf,msgs,a,b);

	writeln("count:",count," sumReads:",a," rest:",b);
	if ((b > 0) && (addBuf.length >= b))
	{
		readObjects(buf~addBuf, msgs, a,b);
		writeln("length:",(buf~addBuf).length," count:",count," sumReads:",a," rest:",b);
	}
	foreach(i; 0..count)
		msgs[i]();

}
*/