import 'dart:async';
import 'dart:ui' as ui show Image;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spritewidget/spritewidget.dart';

// The image map hold all of our image assets.
ImageMap _images;

// The sprite sheet contains an image and a set of rectangles defining the
// individual sprites.
SpriteSheet _sprites;

class ThePrivacyGame extends StatefulWidget {
  ThePrivacyGame({Key key}) : super(key: key);

  static const String routeName = '/';

  @override
  _ThePrivacyGame createState() => new _ThePrivacyGame();
}

class _ThePrivacyGame extends State<ThePrivacyGame> {
  NodeWithSize rootNode;

  // This method loads all assets that are needed for the demo.
  Future<Null> _loadAssets(AssetBundle bundle) async {
    // Load images using an ImageMap

    const imagesToLoad = [
      'assets/02_trees_and_bushes.png',
      'assets/player/run/hero.png'
    ];
    _images = new ImageMap(bundle);
    await _images.load(imagesToLoad);

    // _sprites = new SpriteSheet(_images[''])
  }

  @override
  void initState() {
    // Always call super.initState
    super.initState();

    // Lock to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Get our root asset bundle
    AssetBundle bundle = rootBundle;

    // Load all graphics, then set the state to assetsLoaded and create the
    // WeatherWorld sprite tree
    _loadAssets(bundle).then((_) {
      setState(() {
        assetsLoaded = true;
        thePrivacyWorld = new ThePrivacyWorld();
      });
    });
  }

  bool assetsLoaded = false;
  ThePrivacyWorld thePrivacyWorld;

  @override
  Widget build(BuildContext context) {
    // Until assets are loaded we are just displaying a blue screen.
    // If we were to load many more images, we might want to do some
    // loading animation here.
    if (!assetsLoaded) {
      return new Scaffold(
        appBar: new AppBar(
          title: new Text('Booting up the world'),
        ),
        body: new Container(
          decoration: new BoxDecoration(
            color: const Color(0xff4aaafb),
          ),
        ),
      );
    }

    return new Scaffold(
        appBar: new AppBar(
          title: new Text('The Privacy Game'),
        ),
        body: new Material(
            child: new Stack(
          children: <Widget>[
            new SpriteWidget(thePrivacyWorld),
          ],
        )));
  }
}

// For the different weathers we are displaying different gradient backgrounds,
// these are the colors for top and bottom.
const List<Color> _kBackgroundColorsTop = const <Color>[
  const Color(0xff5ebbd5),
  const Color(0xff0b2734),
  const Color(0xffcbced7)
];

const List<Color> _kBackgroundColorsBottom = const <Color>[
  const Color(0xff4aaafb),
  const Color(0xff4c5471),
  const Color(0xffe0e3ec)
];

GradientNode _background;
Sprite ground = new Sprite.fromImage(_images['assets/02_trees_and_bushes.png']);

Sprite player = new Sprite.fromImage(_images['assets/player/run/hero.png']);

WalkingGround _walkingGround;
MainPlayer _mainPlayer;
int _startTimeMillis;
int seconds = 0;
bool playerMoving = false;
double _walkingGroundPosition = 0.00;

class ThePrivacyWorld extends NodeWithSize {
  ThePrivacyWorld() : super(const Size(1920.0, 1080.0)) {
    _startTimeMillis = new DateTime.now().millisecondsSinceEpoch;
    userInteractionEnabled = true;
    // Start by adding a background.
    _background = new GradientNode(
      this.size,
      _kBackgroundColorsTop[0],
      _kBackgroundColorsBottom[0],
    );

    _walkingGround = new WalkingGround();
    _mainPlayer = new MainPlayer();
    // addChild(_background);
    addChild(_walkingGround);
    addChild(_mainPlayer);
  }

  double playerMoveToRight = 0.0;
  Sprite proceduralGround;
  @override
  void update(double dt) {
    int millis = new DateTime.now().millisecondsSinceEpoch - _startTimeMillis;
    if (playerMoving) {
      _walkingGroundPosition += 8;
      if (_walkingGroundPosition > ground.size.width) {
        // ground.scaleY = ground.scaleX;
        _walkingGroundPosition = 0.0;
      }

      if (((ground.size.width / 2) - _walkingGroundPosition) < 896.0) {
        if (proceduralGround == null) {
          print("Made new ground");
          proceduralGround =
              new Sprite.fromImage(_images['assets/02_trees_and_bushes.png']);
          proceduralGround.zPosition = -1.0;
          proceduralGround.position = Offset(
              3072.0  - _walkingGroundPosition,
              ground.size.height / 4);
          addChild(proceduralGround);
        } else {
          // print("Updating position");
          proceduralGround.position = Offset(
              3072.0  - _walkingGroundPosition,
              ground.size.height / 4);
        }
      } else {
        if (proceduralGround != null) {
          removeChild(proceduralGround);
        }
        proceduralGround = null;
      }

      if (playerMoveToRight < 960) {
        playerMoveToRight += 3;
        player.position = Offset(playerMoveToRight, 750.0);
      }
      ground.position = Offset((ground.size.width / 2) - _walkingGroundPosition,
          ground.size.height / 4);
    }
    // int newSeconds = (millis) ~/ 1000;
    //   if (newSeconds != seconds) {
    //     seconds = newSeconds;
    //     ground.position = Offset(_walkingGroundPosition, -100.00);
    //   }
  }

  @override
  handleEvent(SpriteBoxEvent event) {
    if (event.type == PointerDownEvent) {
      playerMoving = true;
      // removeChild(ground);
      // ground.position = Offset(_walkingGroundPosition, -100.00);
    } else if (event.type == PointerMoveEvent) {
    } else {
      playerMoving = false;
    }

    return true;
  }
}

// The GradientNode performs custom drawing to draw a gradient background.
class GradientNode extends NodeWithSize {
  GradientNode(Size size, this.colorTop, this.colorBottom) : super(size);

  Color colorTop;
  Color colorBottom;

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);

    Rect rect = Offset.zero & size;
    Paint gradientPaint = new Paint()
      ..shader = new LinearGradient(
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.bottomLeft,
          colors: <Color>[colorTop, colorBottom],
          stops: <double>[0.0, 1.0]).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }
}

class WalkingGround extends Node {
  WalkingGround() {
    ground.pivot = const Offset(0.5, 0.5);
    ground.position = Offset(ground.size.width / 2, ground.size.height / 4);
    addChild(ground);
    // player.pivot = const Offset(0.5, 0.5);
    // player.position = Offset(50.0, -110.00);
    // addChild(player);
  }
}

class MainPlayer extends Node {
  MainPlayer() {
    print("MainPlayer done" + player.size.toString());
    player.pivot = const Offset(0.5, 0.5);
    player.position = Offset(0.5, 750.0);
    addChild(player);
  }
}
