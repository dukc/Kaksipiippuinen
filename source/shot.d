module kaksipiippuinen.shot;

import sd = arsd.simpledisplay;
import std.stdio, std.typecons, std.range, std.algorithm;
import kaksipiippuinen.gameObject;
import kaksipiippuinen.bird;
import dlib.math.vector : vec3;

auto ref use(alias code, T)(auto ref T a){return code(a);}

class Shot(Target) : GameObject
{   enum Tuple!(float, "distance", int, "damage")[] damageDistances = [tuple(1.25, 2), tuple(2, 1)];
    enum muzzleVel = vec3(0, 0, 200);

    final override protected void eachStep(float deltaTime)
    {   hitCanditates
        .each!((Target a)
               {auto damage = damageDistances
                   .    find!((b, c) => b.distance ^^ 2 > c.lengthsqr)(position - a.position )
                   ;
               if (!damage.empty) {a.takeDamage(damage.front.damage);}
               });
    }
    abstract protected ForwardRange!Target hitCanditates();
}


