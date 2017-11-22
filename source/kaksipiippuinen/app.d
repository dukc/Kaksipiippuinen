module kaksipiippuinen.app;
import std.random, std.math, std.range, std.algorithm, std.array,
    std.stdio, std.process, std.conv, std.typecons, std.container,
    std.variant, std.traits;
import kaksipiippuinen.bird, kaksipiippuinen.shot, kaksipiippuinen.gameObject, kaksipiippuinen.weapon;
import core.runtime;
import dlangui.core.math3d;
import dlangui;


enum timerDelta = .04f;

mixin APP_ENTRY_POINT;

class GameBoard : CanvasWidget
{   import dlangui.core.types : Rect;

    enum audioDir = "views/audio/";
    enum size = vec3(32, 24, 0);
    enum shotCost = 10.0;
    int drops;
    float time = -1;
    GameObject[] content;
    ulong stepTimer;
    vec2 mousePos;
    Weapon weapon;
    bool[2] mouseButtonsDown;
    from!"derelict.sdl2.mixer".Mix_Chunk*[string] audioChunks;

    static xOf(vec2 pos, Rect transform)
    {   return cast(int)(pos.x / size.x * transform.width) + transform.left;
    }

    static yOf(vec2 pos, Rect transform)
    {   return transform.bottom - cast(int)(pos.y / size.y * transform.height);
    }

    static vecOf(int x, int y, Rect transform)
    {   return vec2
        (   (x - transform.left) * size.x / transform.width,
            -(y - transform.bottom) * size.y / transform.height,
        );
    }

    public void restart()
    {   drops = 0;
        time = 120;
        content.length = 0;
        stepTimer = setTimer(cast(long)(1000 * timerDelta));
        foreach(i; 0 .. 2){content ~= new Bird;}

        weapon =
        {   Weapon createdWeapon = 
            {   ammoMax: 2,
                muzzleVelocity: 200,
                shotRecoveryTime: .4,
                loweringTime: .3,
                cartridgeAddingTime: .5,
                reloadingRecoveryTime: .3,
                raisingTime: .3,
                readyImage: "Barrels",
                recoilImage: "Barrels2",
                ignitionSound: "ShotgunBlast",
            };
            createdWeapon.standardizeState;
            return createdWeapon;
        }();
    }
    
    private class Bird : kaksipiippuinen.bird.Bird
    {   this()
        {   position = vec3(-1, 0.5.uniform(1) * GameBoard.size.y, normalZ);
            velocity = vec3(uniform(10.0, 15.0 + drops * .1), 0, 0);
            if (dice(50, 50))
            {   position.x = GameBoard.size.x + 1;
                velocity.x *= -1;
                //this.size.x *= -1;
            }
        }

        override void takeDamage(int amount){
            auto originallyAlive = hitPoints >= 0;
            auto originalSpeed = velocity.x;
            super.takeDamage(amount);
            if (originallyAlive){
            //tappo
            if(hitPoints < 0){
                drops++;
                time += originalSpeed.abs;
            }
            //haavakko
            else{}
            }
        }
        
        override bool outOfArea(){
            if (-Bird.size.x <= position.x && position.x <= GameBoard.size.x + Bird.size.x)
            return false;
            //haavoittunut
            if (hitPoints != normalHitPoints && hitPoints >= 0){
                time = time * .95 - 10;
            }
            return position.x.sgn == velocity.x.sgn;
        }
    }
    
    auto _hitCanditates()
    {   return  content
        .   map!(a => cast(kaksipiippuinen.bird.Bird)a)
        .   filter!(a => a)
        ;
    }

    override bool onMouseEvent(from!"dlangui".MouseEvent what)
    {   if(time < 0) return false;
        mousePos = vecOf(what.x, what.y, Rect(0, 0, window.width, window.height));

        mouseButtonsDown = 
        [   what.lbutton.isDown,
            what.rbutton.isDown,
        ];

        step(0);

        return true;
    }

    override bool onKeyEvent(KeyEvent what)
    {   if(what.keyCode == KeyCode.F2 && time < 0.0f)
        {   restart;
            return true;
        }
        
        return false;
    }

    override void doDraw(from!"dlangui".DrawBuf buf, Rect area)
    {   import dlangui;
        //buf.fillRect(area, 0x00FFFFFF);
        buf.fill(/*white*/ 0x00FFFFFF);

        content.each!( (GameObject na){
            if(auto a = cast(Bird)na)
            {   //auto drawDir = only(a.size.x.sgn, a.size.y.sgn);
                auto duckImage = drawableCache.getImage(a.image).get;
                auto paintPos = vec2(a.position.vec[0 .. 2]) - a.size / 2;
                buf.drawRescaled
                (   Rect
                    (   xOf(paintPos, area),
                        yOf(paintPos + a.size, area),
                        xOf(paintPos + a.size, area),
                        yOf(paintPos, area),
                    ),
                    duckImage,
                    Rect(0, 0, duckImage.width, duckImage.height),
                );
            }});
            
        if (!weapon.image.empty)
        {   auto barrels = drawableCache.getImage(weapon.image).get;
            buf.drawRescaled
            (
                Rect
                (   xOf(mousePos, area) - area.width / 2,
                    yOf(mousePos, area),
                    xOf(mousePos, area) + area.width / 2,
                    yOf(mousePos, area) + area.height,
                ),
                barrels,
                Rect(0, 0, barrels.width, barrels.height),
            );
        }

        if(true)
        {   bool gameOver = time < 0;
            auto textColor = gameOver? Color.red: Color.black;
            font.drawText(buf, area.left, area.top, "Tiputuksia: "d ~ drops.to!dstring, textColor);
            if(gameOver)
            {   font.drawText(buf, area.left, area.top + 30, "Kiitos pelistä! F2 aloittaaksesi alusta."d, textColor);
            }
            else font.drawText(buf, area.left, area.top + 30, "Aika: "d ~ time.to!int.to!dstring, textColor);
        }
    }

    void step(float delta)
    {   auto weaponResult = weapon.step
        (   delta,
            mouseButtonsDown[0],
            mouseButtonsDown[1]? WeaponProcedure.reload.nullable: Nullable!WeaponProcedure.init,
        );
        
        if (weaponResult[0] !is null)
        {   weaponResult[0].position = vec3(mousePos.vec[] ~ [0.0f]);
            weaponResult[0].hitCanditates = () => _hitCanditates.inputRangeObject;
            content ~= weaponResult[0];
        }

        if (!weaponResult[1].empty) playSound(weaponResult[1]);
        
        if (delta > 0)
        {   auto contentFilter = content
                .map!(a => a.step(delta))
                .array
                ;

            
            immutable exitingShotCount = content
                .zip(contentFilter)
                .filter!(a => !a[1])
                .map!(a => a[0])
                .map!(a => cast(Shot)a)
                .filter!(a => a !is null)
                .walkLength
                ;

            //Vähentää käytettyjen laukausten aikahinnan
            time -= exitingShotCount * shotCost;

            content = content
                .zip(contentFilter)
                .filter!(a => a[1])
                .map!(a => a[0])
                .array
                ;
            time -= delta * (1 + drops/40.0);
        }

        invalidate();
    }
    
    override bool onTimer(ulong timerId)
    {   if (timerId == stepTimer)
        {   //jos peli on päättynyt
            if (time >= 0){} else return false;
            if (dice(96, 4)) content ~= this.new Bird;
            step(timerDelta);
            return true;
        }
        assert(false);
    }

    void playSound(string name)
    {   import derelict.sdl2.mixer;
        import std.string;
        if (audioError != "") return;
        if (!(name in audioChunks))
        {   audioChunks[name] = Mix_LoadWAV(toStringz(audioDir ~ name ~ ".wav"));
        }
        auto entry = audioChunks[name];
        if (entry !is null) Mix_PlayChannel(-1, entry, 0);
    }
}

extern (C) int UIAppMain(string[] args)
{   embeddedResourceList.addResources(embedResourcesFromList!("resources.list")());
    Window window = Platform.instance.createWindow("Kaksipiippuinen", null, WindowFlag.Resizable | WindowFlag.ExpandSize, 640, 480);
    auto board = new GameBoard();
    window.mainWidget = board;
    board.restart;
    window.show;
    if (audioError != "") Log.d("Äänikirjastoa ei pystytty lataamaan: ", audioError);
    else Log.d("Äänikirjasto alustettu normaalisti");
    return Platform.instance.enterMessageLoop();
}

/*auto alive(Bird what){return what.hitPoints > 0;}
unittest{
    auto rabbit = Bird.init;
    assert(rabbit.alive);
    rabbit.hitPoints = 0;
    assert(!rabbit.alive);
    rabbit.hitpoints -= 10;
    assert(!rabbit.alive);
}*/

shared static this()
{   import derelict.sdl2.sdl;
    import derelict.sdl2.mixer;
    import derelict.sdl2.functions;
    import derelict.sdl2.types;
    import derelict.util.exception;
    import std.string;
    
    try
    {   DerelictSDL2.load();
        DerelictSDL2Mixer.load();

        if (SDL_Init( SDL_INIT_VIDEO | SDL_INIT_AUDIO ) < 0)
        {   audioError = SDL_GetError().fromStringz.idup;
        }   else if (Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 2048 ) < 0)
        {   audioError = Mix_GetError().fromStringz.idup;
        }   else audioError = "" /*onnistui*/;
    }
    catch (DerelictException e)
    {   audioError = e.toString;
    }
}

shared string audioError = "Not initialized yet";



//////////////////////////////////////////////////////
//utilites from here-on

auto ref use(alias code, T)(auto ref T a){return code(a);}

//Nielsen-Scherkl lookup
template from(string moduleName)
{
    mixin("import from = " ~ moduleName ~ ";");
}

