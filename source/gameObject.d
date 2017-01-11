module kaksipiippuinen.gameObject;

import dlib.math.vector : vec3;

class GameObject{
    vec3 position;
    vec3 velocity;
    vec3 acceleration = vec3(0, 0, 0);
    protected void eachStep(float){};
    final bool step(float deltaTime){
    position += velocity * deltaTime;
    velocity += acceleration * deltaTime;
    eachStep(deltaTime);
    auto result = !outOfArea;
    return result;
    }
    abstract bool outOfArea();
}
