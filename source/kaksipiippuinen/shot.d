module kaksipiippuinen.shot;

import std.stdio, std.typecons, std.range, std.algorithm;
import kaksipiippuinen.gameObject;
import kaksipiippuinen.bird;
import dlangui.core.logger;
import dlangui.core.math3d;

auto ref use(alias code, T)(auto ref T a){return code(a);}

class Shot : GameObject
{   enum Tuple!(float, "distance", int, "damage")[] damageDistances = [tuple(1.25, 2), tuple(2, 1)];
    float range;
    int kills = 0;
    //Pikaratkaisu jotta saisin tämän luokan konkreettiseksi, oli ennen abstrakti funktio.
    ForwardRange!Bird delegate() hitCanditates;

    final override protected void eachStep(float deltaTime)
    {   foreach(a; hitCanditates())
        {   auto damage = damageDistances
            .    find!((b, c) => b.distance ^^ 2 > c.magnitudeSquared)(position - a.position )
            ;
            if (!damage.empty)
            {   if (a.hitPoints < 0) kills--;
                a.takeDamage(damage.front.damage);
                if (a.hitPoints < 0) kills++;
            }
        }
        range -= velocity.magnitude * deltaTime;
    }

    //pitäisi määritellä vasta pelilaudan yhteydessä... aion luultavasti poistaa abstraktion funktion.
    override bool outOfArea()
    {   return range < 0;
    }
}


