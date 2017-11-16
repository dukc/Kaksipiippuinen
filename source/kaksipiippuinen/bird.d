module kaksipiippuinen.bird;
import kaksipiippuinen.gameObject;
import dlangui.core.math3d;

class Bird : GameObject
{   int hitPoints = normalHitPoints;
    void takeDamage(int amount)
    {   void delegate() onDie = hitPoints >= 0? ()
        {   acceleration.y = -5;
            velocity.x *= .5;
            size = vec2(1.2, 1.2);
        }: ()
        {   velocity.x *= .85;
        };
        hitPoints -= amount;
        velocity.y -= amount;
        hitPoints >= 0? {}: onDie();
    }

    auto size = vec2(1.5, .75);
    enum normalHitPoints = 1;
    enum normalZ = 32;
}


