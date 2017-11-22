module kaksipiippuinen.bird;
import kaksipiippuinen.gameObject;
import dlangui.core.math3d;

class Bird : GameObject
{   int hitPoints = normalHitPoints;
    void takeDamage(int amount)
    {   void delegate() onDie = hitPoints >= 0? ()
        {   acceleration.y = -5;
            velocity.x *= .5;
            size *= vec2(1, 2.0 / 3);
            image = "DuckF";
        }: ()
        {   velocity.x *= .85;
            frameLeft = 0;
        };
        hitPoints -= amount;
        velocity.y -= amount;
        hitPoints >= 0? {}: onDie();
    }

    override void eachStep(float delta)
    {   if (hitPoints >= 0)
        {   frameLeft -= delta;
            while (frameLeft <= 0)
            {   image = image == "Duck1"? "Duck2": "Duck1";
                frameLeft += 0.35f * (hitPoints + 1) / (normalHitPoints + 1);
            }
        }
    }

    auto size = vec2(2, 1);
    auto frameLeft = 0.4;
    auto image = "Duck1";
    enum normalHitPoints = 1;
    enum normalZ = 32;
}


