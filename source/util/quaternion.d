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
*   Модуль для работы с кватернионами
*
*	Кватернионы позволяют описать вращения намного лучше матриц поворота и независимо от 
*	порядка. Также перемножение кватернионов имеет меньшую вычислительную стоимость. Итого движок использует
*	эти замечательные объекты для описания всех вращений.
*/
module util.quaternion;

import util.vector;
import util.matrix;

import std.math;
import std.conv;

/// Точность нормализации кватерниона
/**
*	При работе с плавающей запятой никогда нельзя ожидать,
*	что 2./2. == 1, поэтому задаем интервал, в который должен
*	попасть результат при вычислении.
*/
private enum TEST_DELTA = 0.0001;

const Quaternion ZERO_QUATERNION = Quaternion(0,0,0,0);
const Quaternion UNIT_QUATERNION = Quaternion(1,0,0,0);

/// Математический объект для описания вращения
/**
*	@todo Нужны юниттесты для кватернионов, ибо хз работает ли это все.
*	@todo Конвертация в матрицы поворота и обратно нужны для 4x4, а не для 3x3 матриц
*/
struct Quaternion
{
	double x = 0.;
	double y = 0.;
	double z = 0.;
	double w = 0.;

	/// Создание кватерниона для вращения
	/**
	*	@par vAxis Ось вращения
	*	@par angle Угол вращения, в радианах
	*/
	static Quaternion create(vec3 vAxis, double angle)
	{
		Quaternion ret;
		vAxis.normalize();

		// Нормализуем угол
		while(angle >= PI*2)
		{
			angle -= PI*2;
		}
		while(angle <= -PI*2)
		{
			angle += PI*2;
		}

		auto t = sin(angle/2);
		ret.x = vAxis.x*t;
		ret.y = vAxis.y*t;
		ret.z = vAxis.z*t;
		ret.w = cos(angle/2);
		return ret;
	}

	/// Получение кватерниона из углов Эйлера
	static Quaternion create(double pitch, double yaw, double roll)
	{

		float cos_z_2 = cos(0.5*roll);
		float cos_y_2 = cos(0.5*yaw);
		float cos_x_2 = cos(0.5*pitch);

		float sin_z_2 = sin(0.5*roll);
		float sin_y_2 = sin(0.5*yaw);
		float sin_x_2 = sin(0.5*pitch);

		// and now compute quaternion
		Quaternion ret;
		ret.w = cos_z_2*cos_y_2*cos_x_2 + sin_z_2*sin_y_2*sin_x_2;
		ret.x = cos_z_2*cos_y_2*sin_x_2 - sin_z_2*sin_y_2*cos_x_2;
		ret.y = cos_z_2*sin_y_2*cos_x_2 + sin_z_2*cos_y_2*sin_x_2;
		ret.z = sin_z_2*cos_y_2*cos_x_2 - cos_z_2*sin_y_2*sin_x_2;
		return ret;
	}

	/// Создание кватерниона из матрицы поворота
	static Quaternion create(Matrix!(3) m)
	{
		Quaternion ret;
        float tr = m[0,0] + m[1,1] + m[2,2]; // trace of martix
        if (tr > 0.0f)  // if trace positive than "w" is biggest component
		{    
            ret.x = (m[1,2] - m[2,1]);
			ret.y = (m[2,0] - m[0,2]);
			ret.z = (m[0,1] - m[1,0]);
			ret.w = (tr+1.0f);
			auto t = 0.5/sqrt( ret.w );  // "w" contain the "norm * 4"
			ret.x*=t;
			ret.y*=t;
			ret.z*=t;
			ret.w*=t;
        }
		else if( (m[0,0] > m[1,1] ) && ( m[0,0] > m[2,2]) )  // Some of vector components is bigger
		{
			ret.x = (1.0f + m[0,0] - m[1,1] - m[2,2]);
			ret.y = (m[1,0] + m[0,1]);
			ret.z = (m[2,0] + m[0,2]);
			ret.w = (m[1,2] - m[2,1]);
			auto t = 0.5/sqrt( ret.x ); 
			ret.x*=t;
			ret.y*=t;
			ret.z*=t;
			ret.w*=t;
		}
		else if ( m[1,1] > m[2,2] )
		{
			ret.x = m[1,0] + m[0,1];
			ret.y = 1.0f + m[1,1] - m[0,0] - m[2,2];
			ret.z = m[2,1] + m[1,2];
			ret.w = m[2,0] - m[0,2]; 
			auto t = 0.5/sqrt( ret.y ); 
			ret.x*=t;
			ret.y*=t;
			ret.z*=t;
			ret.w*=t;
		}
		else
		{
			ret.x = m[2,0] + m[0,2];
			ret.y = m[2,1] + m[1,2];
			ret.z = 1.0f + m[2,2] - m[0,0] - m[1,1];
			ret.w = m[0,1] - m[1,0];
			auto t = 0.5/sqrt( ret.z ); 
			ret.x*=t;
			ret.y*=t;
			ret.z*=t;
			ret.w*=t;
		}
		return ret;
	}

	/// Преобразование в матрицу вращения
	Matrix!(4) toMatrix()
	{
		Matrix!(4) ret;
		double wx, wy, wz, xx, yy, yz, xy, xz, zz, x2, y2, z2;
        auto s  = 2./length();  // 4 mul 3 add 1 div
        x2 = x * s;    y2 = y * s;    z2 = z * s;
        xx = x * x2;   xy = x * y2;   xz = x * z2;
        yy = y * y2;   yz = y * z2;   zz = z * z2;
        wx = w * x2;   wy = w * y2;   wz = w * z2;

        ret[0,0] = 1.0f - (yy + zz);
        ret[1,0] = xy - wz;
        ret[2,0] = xz + wy;

        ret[0,1] = xy + wz;
        ret[1,1] = 1.0f - (xx + zz);
        ret[2,1] = yz - wx;

        ret[0,2] = xz - wy;
        ret[1,2] = yz + wx;
        ret[2,2] = 1.0f - (xx + yy);
        ret[3,3] = 1.0f;
		return ret;
	}

	/// Подготовка к вращению
	/**
	*	@par vAxis Вектор оси вращения
	*	@par angle Угол вращения
	*	@note Нужно для использования метода rotate без параметров.
	*	Перед вызовом rotate вызывается данный метод.
	*/
	void prepare(vec3 vAxis, double angle)
	{
		vAxis.normalize();

		// Нормализуем угол
		while(angle >= PI*2)
		{
			angle -= PI*2;
		}
		while(angle <= -PI*2)
		{
			angle += PI*2;
		}

		auto t = sin(angle/2);
		x = vAxis.x*t;
		y = vAxis.y*t;
		z = vAxis.z*t;
		w = cos(angle/2);
	}

	/// Вектор, вокруг происходит вращение
	@property vec3 axis()
	{
		vec3 ret;
		auto angle = acos(w);
		auto t = sin(acos(w));
		ret.x = x/t;
		ret.y = y/t;
		ret.z = z/t;
		return ret;
	}

	/// Получение векторной части
	@property vec3 vec()
	{
		vec3 ret;
		ret.x = x;
		ret.y = y;
		ret.z = z;
		return ret;
	}

	/// Задание векторной части
	@property void vec(vec3 v)
	{
		x = v.x;
		y = v.y;
		z = v.z;
	}

	/// Получение скалярной части
	@property double scalar()
	{
		return w;
	}

	/// Задание скалярной части
	@property void scalar(double val)
	{
		w = val;
	}

	/// Получение угла, вокруг которого вращают
	@property double angle()
	{
		return 2*acos(w);
	}

	/// Сложение
	Quaternion opBinary(string op)(Quaternion q) if(op=="+")
	{
		Quaternion ret;
		ret.x = x + q.x;
		ret.y = y + q.y;
		ret.z = z + q.z;
		ret.w = w + q.w;
		return ret;
	}

	/// Вычитание
	Quaternion opBinary(string op)(Quaternion q) if(op=="-")
	{
		Quaternion ret;
		ret.x = x - q.x;
		ret.y = y - q.y;
		ret.z = z - q.z;
		ret.w = w - q.w;
		return ret;
	}

	/// Умножение
	Quaternion opBinary(string op)(Quaternion q) if(op=="*")
	{
		Quaternion ret; // a = w, b = x, c = y, d = z
		ret.x = w*q.x + x*q.w + y*q.z - z*q.y; // a1*b2+b1*a2+c1*d2-d1*c2
		ret.y = w*q.y - x*q.z + y*q.w + z*q.x; // a1*c2-b1*d2+c1*a2+d1*b2
		ret.z = w*q.z + x*q.y - y*q.x + z*q.w; // a1*d2+b1*c2-c1*b2+d1*a2
		ret.w = w*q.w - x*q.x - y*q.y - z*q.z; // a1*a2-b1*b2-c1*c2-d1*d2
		return ret;
	}

	/// Длина
	@property double length()
	{
		return sqrt(w*w + x*x + y*y + z*z);
	}

	/// Длина в квадрате
	@property double length2()
	{
		return w*w + x*x + y*y + z*z;
	}

	/// Сопряжение
	Quaternion conjugation()
	{
		Quaternion ret;
		ret.x = x;
		ret.y = y;
		ret.z = z;
		ret.w = -w;
		return ret;
	}

	/// Получение кватерниона единичной длины
	void normalize()
	{
		auto l = length;
		x = x/l;
		y = y/l;
		z = z/l;
	}

	/// Обратный кватернион
	Quaternion invert()
	{
		Quaternion ret = conjugation();
		auto l = length;
		ret.x /= l;
		ret.y /= l;
		ret.z /= l;
		return ret;
	}

	/// Поворот вектора, вокруг заданной оси
	/**
	*	@par v Вектор, который мы вращаем
	*	@note Для использования этой функции
	*	кватернион должен быть уже настроен на
	*	поворот с помощью create(vec3 vAxis, double angle)
	*	или prepare(vec3 vAxis, double angle)
	*/
	vec3 rotate(vec3 v)
	in
	{
		assert(abs(length-1.)<=TEST_DELTA, "Quaternion need to be prepared with method 'prepare', length ("~to!string(length)~") with accuracy ("~to!string(TEST_DELTA)~") didn't match expected value (1).");	
	}
	body	
	{
		Quaternion vq;
		vq.vec = v;
		vq.w = 0.0f;
		auto vqt = this*vq*conjugation();
		return vqt.vec*(-1);
	}

	/// Поворот вектора вокруг оси
	/**
	*	@par v Вектор, который мы вращаем
	*	@par vAxis Ось вращения
	*	@par angle Угол вращения
	*	@note Данный метод является оберткой для двух функций
	*	prepare и rotate без параметров.
	*/
	vec3 rotate(vec3 v, vec3 vAxis, double angle)
	{
		prepare(vAxis, angle);
		return rotate(v);
	}
}

unittest
{
	import std.stdio;
	import std.math;
	import std.conv;

	import util.matrix;

	write("Testing quaternion... ");
	scope(success) writeln("Finished!");
	scope(failure) writeln("Failed!");
	
	Quaternion quat = Quaternion.create(vec3(0,1,0), PI/2.0f);
	auto vec = quat.rotate(vec3(1.0f,0.0f,0.0f));
	//assert(approxEqual(vec.x,0) && vec.y == 0 && approxEqual(vec.z,1), "Quaternion rotation failed! v="~to!string(vec)); 

	vec = quat.rotate(vec);
	//assert(approxEqual(vec.x,-1) && vec.y == 0 && approxEqual(vec.z,0), "Quaternion rotation failed! v="~to!string(vec)); 

	// Тотально тестируем поворот с помощью матриц
	// если не совпали результаты - фейл
	vec3 a = vec3(1.0f,2.0f,3.0f);

	for(float angle = 0.0f; angle <= 2*PI; angle+=PI/20.0f)
	{
		auto b = rotationMtrx3(angle, 0.0f, 0.0f)*a;
		auto q = Quaternion.create(angle, 0.0f, 0.0f);
		auto c = q.rotate(a);
		assert(b == c, text("Rotation pitch test failed for angle = ",angle,". ",b," != ", c));
	}

	a = vec3(1.0f,2.0f,3.0f);
	for(float angle = 0.0f; angle <= 2*PI; angle+=PI/20.0f)
	{
		auto b = rotationMtrx3(0.0f, angle, 0.0f)*a;
		auto q = Quaternion.create(0.0f, angle, 0.0f);
		auto c = q.rotate(a);
		assert(b == c, text("Rotation yaw test failed for angle = ",angle,". ",b," != ", c));
	}

	a = vec3(1.0f,2.0f,3.0f);
	for(float angle = 0.0f; angle <= 2*PI; angle+=PI/20.0f)
	{
		auto b = rotationMtrx3(0.0f, 0.0f, angle)*a;
		auto q = Quaternion.create(0.0f, 0.0f, angle);
		auto c = q.rotate(a);
		assert(b == c, text("Rotation roll test failed for angle = ",angle,". ",b," != ", c));
	}

}
