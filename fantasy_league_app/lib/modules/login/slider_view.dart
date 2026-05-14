import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/themes.dart';

class SliderView extends StatefulWidget {
  const SliderView({super.key});

  @override
  _SliderViewState createState() => _SliderViewState();
}

class _SliderViewState extends State<SliderView> {
  var pageController = PageController(initialPage: 0);

  int pageNumber = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Flexible(
            child: Container(
              child: PageView(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (number) {
                  setState(() {
                    pageNumber = number;
                  });
                },
                children: const <Widget>[
                  ImageListView(
                    imageAsset: 'assets/cricketImage1.png',
                    txt: 'Select A Match',
                    subTxt:
                        'Select any of the upcoming matches from any of the current or\nupcoming game series',
                  ),
                  ImageListView(
                    imageAsset: 'assets/cricketImage2.png',
                    txt: 'Join A Contest',
                    subTxt:
                        'join any free or cash contest to win cash and the ultimate\nbragging rights to showoff your improvement in the free/Skill\ncontests on Fixturers!',
                  ),
                  ImageListView(
                    imageAsset: 'assets/cricketImage3.png',
                    txt: 'Create Your Team',
                    subTxt:
                        'Use your sports knowledge and showcase your skills to create\nyour team within a budget of 100 credits',
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: pageNumber == 0
                    ? AllCoustomTheme.getThemeData().colorScheme.surface
                    : AllCoustomTheme.getThemeData()
                        .colorScheme
                        .surface
                        .withValues(alpha: 128),
                radius: 6,
              ),
              const SizedBox(
                width: 6,
              ),
              CircleAvatar(
                backgroundColor: pageNumber == 1
                    ? AllCoustomTheme.getThemeData().colorScheme.surface
                    : AllCoustomTheme.getThemeData()
                        .colorScheme
                        .surface
                        .withValues(alpha: 128),
                radius: 6,
              ),
              const SizedBox(
                width: 6,
              ),
              CircleAvatar(
                backgroundColor: pageNumber == 2
                    ? AllCoustomTheme.getThemeData().colorScheme.surface
                    : AllCoustomTheme.getThemeData()
                        .colorScheme
                        .surface
                        .withValues(alpha: 128),
                radius: 6,
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}

class ImageListView extends StatelessWidget {
  final String? imageAsset;
  final String? txt;
  final String? subTxt;

  const ImageListView(
      {super.key, this.imageAsset, this.txt = '', this.subTxt = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              child: Image.asset(imageAsset!),
            ),
          ),
        ],
      ),
    );
  }
}
