static import arsd.simpledisplay;
alias sd = arsd.simpledisplay;
import std.stdio;
import gameObject;

class Bird : GameObject{
	int hitPoints = normalHitPoints;

	void takeDamage(int amount)
	{  writeln("hit!");
		void delegate() onDie = hitPoints > 0? (){acceleration.y = -5;}: (){};
		hitPoints -= amount;
		velocity.y -= amount;
		hitPoints > 0? {}: onDie();
	}

	//Koska liittyy grafiikkaan, voisi määritellä ehkä mieluummin muualla.
	enum size = sd.Point(30, 10);
	enum normalHitPoints = 2;
	enum normalZ = 32;
}


