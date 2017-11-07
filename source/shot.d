module kaksipiippuinen.shot;

import std.stdio, std.typecons, std.range, std.algorithm;
import kaksipiippuinen.gameObject;
import kaksipiippuinen.bird;
import dlangui.core.math3d;

auto ref use(alias code, T)(auto ref T a){return code(a);}

class Shot(Target) : GameObject
{   enum Tuple!(float, "distance", int, "damage")[] damageDistances = [tuple(1.25, 2), tuple(2, 1)];
    enum muzzleVel = vec3(0, 0, 200);

    final override protected void eachStep(float deltaTime)
    {   foreach(a; hitCanditates)
        {   auto damage = damageDistances
            .    find!((b, c) => b.distance ^^ 2 > c.magnitudeSquared)(position - a.position )
            ;
            if (!damage.empty)
            {   onHit(a, damage.front.damage);
            }
        }
    }

    void onHit(Target victim, int damage)
    {   victim.takeDamage(damage);
    };
    abstract protected ForwardRange!Target hitCanditates();
}


