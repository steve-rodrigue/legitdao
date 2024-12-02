import 'package:flutter/material.dart';
import '../widgets/visuals/header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Header(
            value: 'home_title',
            isLarge: true,
          ),
          Padding(
            padding: EdgeInsets.all(5.0),
            child: const Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer pellentesque tellus ac libero euismod, at maximus justo cursus. Nulla a euismod nunc, sit amet tincidunt ante. Etiam commodo, risus ut sagittis luctus, mauris purus lobortis neque, ut molestie mauris purus a dui. Vestibulum vulputate lorem ut libero laoreet auctor. Integer in euismod purus, nec interdum sapien. Donec sed commodo turpis. Quisque condimentum vulputate mattis. Cras a enim et justo fermentum ornare tempus eu augue. Integer augue eros, fringilla sit amet euismod sed, dictum in arcu.",
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5.0),
            child: const Text(
              "Mauris ac egestas est. Aenean pulvinar tortor vitae nunc vehicula cursus. Ut ut euismod purus. Curabitur tempor magna vitae dui dignissim mattis vel id nisl. Nunc pellentesque justo a eros laoreet, in finibus justo malesuada. Vivamus at volutpat ante. Donec pulvinar fermentum sapien, ut congue urna viverra vel. Aliquam vel pellentesque lorem. Aliquam erat volutpat. Vestibulum et neque ex. Cras pretium, nisi nec ultricies sollicitudin, risus orci aliquam erat, a interdum enim risus vel nulla. Nulla nec lectus sed nulla convallis fermentum. In cursus sapien et lacus venenatis, nec viverra purus commodo. Sed non congue dolor. Duis id nulla sit amet felis commodo rutrum. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. ",
            ),
          ),
        ],
      ),
    );
  }
}
