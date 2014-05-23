// written in the D programming language
/**
*   Copyright: © 2013-2014 Anton Gushcha
*   License: Subject to the terms of the GPL-3.0 license, as written in the included LICENSE file.
*   Authors: Anton Gushcha <ncrashed@gmail.com>
*
*	Describes player camera and handles hard operations with view matrix.
*
*	TODO: movement on Bezier curves, accelerated movement
*	Authors: Gushcha Anton (NCrashed)
*/
module client.camera;

import util.matrix;
import util.vector;
import util.quaternion;
import util.common;
import std.math;

/**
*	Describes maximum up angle to prevent some glitches.
*/
enum UP_DIR_EPSILON = 0.05;

/**
*	Camera calculates view matrix based on camera coordinats, up vector and view vector/
*	Only one camera can be active in same time.
*/
class Camera
{
	this()
	{
		up.y = 1.;
	}

	/// Camera direction vector
	@property vec3 dir()
	{
		auto ret = mTarget-mPos;
		ret.normalize();
		return ret;
	}

	/// Camera left vector
	@property vec3 left()
	{
		return mUp.cross(dir).normalized;
	}

	/// Camera posion
	@property ref vec3 position()
	{
		return mPos;
	}

	/// Camera posion
	@property void position(vec3 val)
	{
		mPos = val;
	}

	/// Camera up vector
	@property ref vec3 up()
	{
		return mUp;
	}

	/// Camera up vector
	@property void up(vec3 val)
	{
		mUp = val;
		mUp.normalize();
	}

	/// Camera target position
	@property ref vec3 target()
	{
		return mTarget;
	}

	/// Camera target position
	@property void target(vec3 val)
	{
		mTarget = val;
	}

	/// Getts camera view matrix
	Matrix!4 getMatrix()
	{
		return lookAt(mPos, mTarget, mUp);
	}

	/**
	*	Rotates camera around $(B axis) vector by $(B angle) radians.
	*/
	void rotate(vec3 axis, Radian angle)
	{
		import std.stdio;
		if(angle == 0) return;

		vec3 temp = mTarget-mPos;
		axis.normalize();
		auto quat = Quaternion.create(axis, angle);
		vec3 temp2 = quat.rotate(temp);

		auto targetold = mTarget;
		mTarget = mPos + temp2;

		// Критические углы
		/*if((temp2-up).length2 <= UP_DIR_EPSILON)
		{
			mTarget = targetold;
		} else if((temp2+up).length2 <= UP_DIR_EPSILON)
		{
			mTarget = targetold;
		}*/
	}

	/**
	*	Rotates camera aroun direction vector by $(B angle) radians.
	*/
	void roll(Radian angle)
	{
		auto quat = Quaternion.create(dir, angle);
		mUp = quat.rotate(mUp);
	}
	
	/**
	*	Linear absolute camera movement to $(B pos) vector in the give time $(B interval).
	*	If $(B interval) is zero, then camera will be moved instantly.
	*/
	void move(vec3 pos, double interval = 0.)
	{
		if (approxEqual(interval,0.))
		{
			mTarget = mTarget + (pos-mPos);
			mPos = pos;
		}
		else
		{
			newpos = pos;
			newpostime = interval;
			newposvel = (newpos-mPos).length/interval;
		}
	}

	/**
	*	Linear releative camera movement by $(B pos) vector in the give time $(B interval).
	*	If $(B interval) is zero, then camera will be moved instantly.
	*/
	void moveRel(vec3 delta, double interval = 0.)
	{
		delta = delta*(-1);
		if (approxEqual(interval,0.))
		{
			mTarget = mTarget + delta;
			mPos = mPos + delta;
		}
		else
		{
			newpos = mPos+delta;
			newpostime = interval;
			newposvel = (newpos-mPos).length/interval;
		}
	}

	/**
	*	Updates camera position. $(B dt) describes how much time
	*	has passed after previously call.
	*/
	void update(double dt)
	{
		if(newpostime>0.)
		{
			if(newpostime <= dt) dt = newpostime;
			auto dvec = newpos - mPos;
			dvec.normalize();
			dvec = dvec*(newposvel*dt);

			mPos = mPos + dvec;
			mTarget = mTarget + dvec;

			newpostime -= dt;
			if(newpostime < 0) newpostime = 0.;
		}
	}
	
private:
	vec3 mPos;
	vec3 mUp;
	vec3 mTarget;

	// Сохранение новой позиции
	vec3 newpos;
	// Оставшееся время для перемещения
	double newpostime;
	// Скорость перемещения
	float newposvel;
}