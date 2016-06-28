import dlib.math.vector : vec3;

class GameObject
{	vec3 position;
	vec3 velocity;
	vec3 acceleration = vec3(0, 0, 0);
	protected void eachStep(float){};
	final bool step(float deltaTime)
    {	eachStep(deltaTime);
		position += velocity * deltaTime;
		velocity += acceleration * deltaTime;
		auto result = !outOfArea;
		if(result){retire;}
		return result;
	}
	abstract bool outOfArea();
	void retire(){};
}
