import sd = arsd.simpledisplay;
import std.stdio, std.typecons, std.range, std.algorithm;
import gameObject;
import bird;
import dlib.math.vector : vec3;

auto ref use(alias code, T)(auto ref T a){return code(a);}

class Shot(T1) : GameObject
	if(isInputRange!T1 && is(typeof(T1.front) : Bird) )
{	//Koska liittyy grafiikkaan, voisi määritellä ehkä mieluummin muualla.
	enum Tuple!(float, "distance", int, "damage")[] damageDistances = [tuple(1.25, 2), tuple(2, 1)];
	enum muzzleVel = vec3(0, 0, 200);
	final override protected void eachStep(float deltaTime)
	{	hitCanditates().each!((Bird a)
		{	auto damage = damageDistances
			.	find!((b, c) => b.distance ^^ 2 > c.lengthsqr)(position - a.position )
			;
			if (!damage.empty) {a.takeDamage(damage.front.damage);}
		});
	}
	abstract protected T1 hitCanditates();
}


