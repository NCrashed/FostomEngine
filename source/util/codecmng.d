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
*
*   Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
*
*	Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
*	Ищет подходящий кодек по расширению или ключевому слову.
*/
module util.codecmng;

public import util.codec;
import util.log;
import util.singleton;

/// Менджер управляет набором доступных кодеков, регистрирует, исключает кодеки.
class CodecMng
{
	mixin Singleton!CodecMng;

	/// Зарегистрировать кодек в менджере
	/**
	*	@par inst Экземпляр кодека
	*	@return true при успехе, false при неудаче
	*/
	bool registerCodec(Codec inst)
	{
		if( inst.type in mCodecs )
		{
			writeLog("CodecMng: codec "~inst.type~" already have been registered!", LOG_ERROR_LEVEL.WARNING);
			return false;
		}

		mCodecs[inst.type] = inst;
		return true;
	}

	/// Получение кодека по идентификатору
	/**
	*	@par type Идентификатор кодека
	*	@note Кидает исключение, если не зарегистрирован.
	*/
	Codec getCodec(string type)
	{
		if( type in mCodecs )
			return mCodecs[type];

		writeLog("CodecMng: Cannot find codec "~type~"!", LOG_ERROR_LEVEL.FATAL);
		throw new Exception("CodecMng: Cannot find codec "~type~"!");
	}

	/// Получение списка кодеков одного стандарта
	/**
	*	Возвращает список кодеков, поддерживающих единный
	*	стандарт.
	*/
	Codec[] getByStandart(string standart)
	{
		auto ret = new Codec[0];

		foreach(c; mCodecs)
			if(c.standart == standart) 
				ret ~= c;

		return ret;
	}

private:
	Codec[string] mCodecs;
}
