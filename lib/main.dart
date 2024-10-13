import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameModel(),
      child: MaterialApp(
        title: 'Card Matching Game',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: CardGameScreen(),
      ),
    );
  }
}

class CardModel {
  final String assetPath;
  bool isFaceUp;
  bool isMatched;

  CardModel(
      {required this.assetPath, this.isFaceUp = false, this.isMatched = false});
}

class GameModel extends ChangeNotifier {
  List<CardModel> _cards = [];
  CardModel? _firstSelectedCard;
  bool _isBusy = false;
  int _score = 0;
  Timer? _timer;
  int _secondsElapsed = 0;

  List<CardModel> get cards => _cards;
  int get score => _score;
  int get secondsElapsed => _secondsElapsed;

  GameModel() {
    _initializeCards();
    _startTimer();
  }

  void _initializeCards() {
    List<String> images = [
      'img/cat.png',
      'img/cat.png',
      'img/dog.jpg',
      'img/dog.jpg',
      'img/duck.jpg',
      'img/duck.jpg',
      'img/moon.jpeg',
      'img/moon.jpeg',
      'img/rabbit.jpg',
      'img/rabbit.jpg',
      'img/spade.jpg',
      'img/spade.jpg',
      'img/star.jpeg',
      'img/star.jpeg',
      'img/sun.png',
      'img/sun.png',
    ];

    images.shuffle();
    _cards = images.map((image) => CardModel(assetPath: image)).toList();
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void flipCard(CardModel card) {
    if (_isBusy || card.isFaceUp || card.isMatched) return;

    card.isFaceUp = true;
    notifyListeners();

    if (_firstSelectedCard == null) {
      _firstSelectedCard = card;
    } else {
      _isBusy = true;
      _checkMatch(card);
    }
  }

  void _checkMatch(CardModel secondCard) {
    if (_firstSelectedCard?.assetPath == secondCard.assetPath) {
      _firstSelectedCard?.isMatched = true;
      secondCard.isMatched = true;
      _score += 10; // Increase score on correct match
      _firstSelectedCard = null;
    } else {
      _score -= 5; // Deduct score on incorrect match
      Future.delayed(Duration(seconds: 1), () {
        _firstSelectedCard?.isFaceUp = false;
        secondCard.isFaceUp = false;
        _firstSelectedCard = null;
        _isBusy = false;
        notifyListeners();
      });
    }
    _isBusy = false;
    notifyListeners();
  }

  bool checkWin() {
    return _cards.every((card) => card.isMatched);
  }

  void resetGame() {
    _score = 0;
    _secondsElapsed = 0;
    _firstSelectedCard = null;
    _isBusy = false;
    stopTimer();
    _initializeCards();
    _startTimer();
    notifyListeners();
  }
}

class GameCard extends StatelessWidget {
  final bool isFlipped;
  final String imageAssetPath;
  final VoidCallback onTap;

  GameCard(
      {required this.isFlipped,
      required this.imageAssetPath,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isFlipped ? Colors.transparent : Colors.blueAccent,
        ),
        child: isFlipped
            ? Image.asset(imageAssetPath) // Front of the card
            : Center(
                child: Text(
                  "Flip Me!",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ), // Back of the card
      ),
    );
  }
}

class CardGameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameModel = context.watch<GameModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Card Matching Game')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: ${gameModel.secondsElapsed}s',
                    style: TextStyle(fontSize: 18)),
                Text('Score: ${gameModel.score}',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          Expanded(child: buildGameGrid(context)),
          if (gameModel.checkWin()) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("You Win!",
                  style: TextStyle(fontSize: 24, color: Colors.green)),
            ),
            ElevatedButton(
              onPressed: () {
                gameModel
                    .resetGame(); // Reset the game when Play Again is pressed
              },
              child: Text('Play Again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildGameGrid(BuildContext context) {
    final gameModel = context.watch<GameModel>();
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      itemCount: gameModel.cards.length,
      itemBuilder: (context, index) {
        final card = gameModel.cards[index];
        return GameCard(
          isFlipped: card.isFaceUp || card.isMatched,
          imageAssetPath: card.assetPath,
          onTap: () {
            gameModel.flipCard(card);
          },
        );
      },
    );
  }
}
