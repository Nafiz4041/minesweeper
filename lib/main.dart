import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:minesweeper/admob.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Minesweeper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        fontFamily: 'Helvetica', // Using system font
      ),
      home: const LevelSelectionScreen(),
      debugShowCheckedModeBanner: false, // Add this line
    );
  }
}

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({Key? key}) : super(key: key);

  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int highestCompletedLevel = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper Levels'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select a Level',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 50,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final isUnlocked = level <= highestCompletedLevel + 1;
                    return LevelButton(
                      level: level,
                      isUnlocked: isUnlocked,
                      onPressed: isUnlocked
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MinesweeperGame(
                                    initialLevel: level,
                                    onLevelComplete: (completedLevel) {
                                      setState(() {
                                        if (completedLevel >
                                            highestCompletedLevel) {
                                          highestCompletedLevel =
                                              completedLevel;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelButton extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final VoidCallback? onPressed;

  const LevelButton({
    Key? key,
    required this.level,
    required this.isUnlocked,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: isUnlocked ? 4 : 0,
      borderRadius: BorderRadius.circular(12),
      color: isUnlocked ? Colors.white : Colors.grey[300],
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MinesweeperGame extends StatefulWidget {
  final int initialLevel;
  final Function(int) onLevelComplete;

  const MinesweeperGame({
    Key? key,
    required this.initialLevel,
    required this.onLevelComplete,
  }) : super(key: key);

  @override
  _MinesweeperGameState createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  late List<List<Cell>> grid;
  bool isGameOver = false;
  int revealedCount = 0;
  late int currentLevel;
  late int rows;
  late int cols;
  late int mineCount;
  int lives = 3; // Start with 3 lives

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel;
    _initializeLevel();
    MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds));
    createRewardedInterstitialAd();
  }

  void _initializeLevel() {
    rows = 8 + (currentLevel ~/ 2);
    cols = 8 + (currentLevel ~/ 2);
    mineCount = 10 + currentLevel;
    if (currentLevel > 50) {
      currentLevel = 50;
      rows = 33;
      cols = 33;
      mineCount = 60;
    }
    _initializeGame();
  }

  void _initializeGame() {
    grid = List.generate(rows, (i) => List.generate(cols, (j) => Cell(i, j)));
    _placeMines();
    _calculateAdjacentMines();
    revealedCount = 0;
    isGameOver = false;
  }

  void _placeMines() {
    Random random = Random();
    int minesPlaced = 0;

    while (minesPlaced < mineCount) {
      int row = random.nextInt(rows);
      int col = random.nextInt(cols);

      if (!grid[row][col].isMine) {
        grid[row][col].isMine = true;
        minesPlaced++;
      }
    }
  }

  void _calculateAdjacentMines() {
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (!grid[i][j].isMine) {
          grid[i][j].adjacentMines = _countAdjacentMines(i, j);
        }
      }
    }
  }

  int _countAdjacentMines(int row, int col) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
          if (grid[newRow][newCol].isMine) {
            count++;
          }
        }
      }
    }
    return count;
  }

  void _revealRandomMine() {
    if (isGameOver) return;

    // Find all hidden mines
    List<Cell> hiddenMines = [];
    for (var row in grid) {
      for (var cell in row) {
        if (cell.isMine && !cell.isRevealed) {
          hiddenMines.add(cell);
        }
      }
    }

    if (hiddenMines.isNotEmpty) {
      // Randomly select one mine
      Cell randomMine = hiddenMines[Random().nextInt(hiddenMines.length)];

      setState(() {
        randomMine.isRevealed = true;
        revealedCount++;

        // Check if the game is over (win condition)
        if (revealedCount == rows * cols - mineCount) {
          _gameOver(true);
        }
      });
    }
  }

  void _revealCell(int row, int col) {
    if (isGameOver || grid[row][col].isRevealed || grid[row][col].isFlagged) {
      return;
    }

    setState(() {
      grid[row][col].isRevealed = true;
      revealedCount++;

      if (grid[row][col].isMine) {
        lives--; // Decrease a life
        if (lives <= 0) {
          _gameOver(false); // End game if lives are 0
        }
      } else if (grid[row][col].adjacentMines == 0) {
        _revealAdjacentCells(row, col);
      }

      if (revealedCount == rows * cols - mineCount) {
        _gameOver(true);
      }
    });
  }

  void _revealAdjacentCells(int row, int col) {
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
          if (!grid[newRow][newCol].isRevealed &&
              !grid[newRow][newCol].isMine) {
            _revealCell(newRow, newCol);
          }
        }
      }
    }
  }

  void _toggleFlag(int row, int col) {
    if (isGameOver || grid[row][col].isRevealed) {
      return;
    }

    setState(() {
      grid[row][col].isFlagged = !grid[row][col].isFlagged;
    });
  }

  void _gameOver(bool isWin) {
    isGameOver = true;
    String message = isWin ? 'You Win!' : 'Game Over!';

    if (isWin) {
      widget.onLevelComplete(currentLevel);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(message),
          content: Text(isWin
              ? 'Congratulations! You\'ve completed level $currentLevel.'
              : 'Better luck next time!'),
          actions: [
            TextButton(
              child: const Text('Back to Level Selection'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  Text(isWin && currentLevel < 50 ? 'Next Level' : 'Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  if (isWin && currentLevel < 50) {
                    currentLevel++;
                  }
                  _initializeLevel();
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minesweeper - Level $currentLevel'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        child: const Icon(Icons.movie),
                        onTap: () {
                          if (rewardedInterstitialAd != null) {
                            rewardedInterstitialAd!.show(
                              onUserEarnedReward:
                                  (AdWithoutView ad, RewardItem reward) {
                                _revealRandomMine(); // Reveal a mine when the reward is earned
                              },
                            );
                          } else {
                            print('Ad not ready yet');
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mines: $mineCount',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Grid: ${rows}x$cols',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      lives,
                      (index) =>
                          Icon(Icons.favorite, color: Colors.red, size: 30),
                    ),
                  ),
                  SizedBox(height: 16), // Add spacing
                ],
              ),
            ),
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 1,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ cols;
                      int col = index % cols;
                      return GestureDetector(
                        onTap: () => _revealCell(row, col),
                        onLongPress: () => _toggleFlag(row, col),
                        child: CellWidget(cell: grid[row][col]),
                      );
                    },
                    itemCount: rows * cols,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Cell {
  final int row;
  final int col;
  bool isMine;
  bool isRevealed;
  bool isFlagged;
  int adjacentMines;

  Cell(this.row, this.col)
      : isMine = false,
        isRevealed = false,
        isFlagged = false,
        adjacentMines = 0;
}

class CellWidget extends StatelessWidget {
  final Cell cell;

  const CellWidget({Key? key, required this.cell}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cellColor = Colors.grey[300]!;
    Widget cellContent = const SizedBox();

    if (cell.isRevealed) {
      cellColor = Colors.white;
      if (cell.isMine) {
        cellContent = const Icon(Icons.brightness_7, color: Colors.black);
      } else if (cell.adjacentMines > 0) {
        cellContent = Text(
          '${cell.adjacentMines}',
          style: TextStyle(
            color: _getNumberColor(cell.adjacentMines),
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else if (cell.isFlagged) {
      cellContent = const Icon(Icons.flag, color: Colors.red);
    }

    return Container(
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(child: cellContent),
    );
  }

  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.brown;
      case 6:
        return Colors.cyan;
      case 7:
        return Colors.black;
      case 8:
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
