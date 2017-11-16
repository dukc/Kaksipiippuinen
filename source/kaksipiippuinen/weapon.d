module kaksipiippuinen.weapon;
import kaksipiippuinen.shot;
import std.typecons, std.conv;
import dlangui.core.math3d;

enum WeaponState {raising, lowering, reloading, closing, firing};

enum WeaponProcedure {reload};

struct Weapon
{   int ammoMax;
    float muzzleVelocity;
    float shotRecoveryTime;
    float loweringTime;
    float raisingTime;
    float cartridgeAddingTime;
    float reloadingRecoveryTime;
    string readyImage;
    string recoilImage;
    string ignitionSound;
    string emptyFireSound;
    string chamberOpeningSound;
    string chamberClosingSound;
    string cartridgeEnterSound;
    
    WeaponState state;
    float recovery;
    int ammo;
    bool triggerDown;
    string image;

    
    void standardizeState()
    {   state = WeaponState.firing;
        recovery = 0;
        ammo = ammoMax;
        triggerDown = false;
        image = readyImage;
    }

    Tuple!(Shot, string) step(in float delta, in bool triggerPressed, in Nullable!WeaponProcedure command = Nullable!WeaponProcedure.init)
    {
        Shot potentialShot;
        string sound;
        
        recovery -= delta;
        immutable triggerWasDown = triggerDown;
        //Aseessa on varmistin, siksi sen ollessa alhaalla ei voi liipaista.
        if (state == WeaponState.firing) triggerDown = triggerPressed;
        if (!triggerWasDown && triggerDown)
        //Iskuri lyö!
        {   if (ammo > 0)
            //laukaus
            {   potentialShot = new Shot();
                potentialShot.velocity = vec3(0, 0, muzzleVelocity);
                //Jos ampuu liian nopeasti laukaus menee (sorsien sijaan) harakoille.
                if (recovery <= 0) potentialShot.range = 50;
                else potentialShot.range = 0;
                sound = ignitionSound;
                recovery += shotRecoveryTime;
                image = recoilImage;
                ammo--;
            }
            else
            //naks
            {   sound = emptyFireSound;
            }
        }

        loop: while (recovery <= 0) final switch(state)
        {   case WeaponState.raising:
                state = WeaponState.firing;
            break;
            case WeaponState.reloading:
                ammo += 1;
                sound = cartridgeEnterSound;
                if (ammo >= ammoMax)
                {   state = WeaponState.closing;
                    recovery += reloadingRecoveryTime;
                }
                else
                {   state = WeaponState.reloading;
                    recovery += cartridgeAddingTime;
                }
            break;
            case WeaponState.lowering:
                sound = chamberOpeningSound;
                image = "";
                if (ammo >= ammoMax)
                {   state = WeaponState.closing;
                    recovery += reloadingRecoveryTime;
                }
                else
                {   state = WeaponState.reloading;
                    recovery += cartridgeAddingTime;
                }
            break;
            case WeaponState.closing:
                state = WeaponState.raising;
                sound = chamberClosingSound;
                image = recoilImage;
                recovery += raisingTime;
            break;
            case WeaponState.firing:
                if (!command.isNull) final switch(command.get)
                {   case WeaponProcedure.reload:
                        //varmistin päälle, liipaisin ei voi jäädä pohjaan
                        triggerDown = false;
                        state = WeaponState.lowering;
                        recovery += loweringTime;
                        image = recoilImage;
                    break;
                }   else
                {   image = readyImage;
                    break loop; //ei tehdä mitään
                }
            break;
        }

        //Muuten kertyisi toimintoon kulunutta aikaa "varastoon" kun ei tee mitään.
        if (recovery < 0) recovery = 0;

        return tuple(potentialShot, sound);
    }
}

//Nielsen-Scherkl lookup
template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}
