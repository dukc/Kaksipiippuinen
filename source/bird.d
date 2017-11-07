module kaksipiippuinen.bird;
import kaksipiippuinen.gameObject;
import dlangui.core.math3d;

class Bird : GameObject
{   int hitPoints = normalHitPoints;
    void takeDamage(int amount)
    {   void delegate() onDie = hitPoints >= 0? (){acceleration.y = -5;}: (){};
        hitPoints -= amount;
        velocity.y -= amount;
        hitPoints >= 0? {}: onDie();
    }

    enum size = vec2(1.5, 0.5);
    enum normalHitPoints = 1;
    enum normalZ = 32;
}


