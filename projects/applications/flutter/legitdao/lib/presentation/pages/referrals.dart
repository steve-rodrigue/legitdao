import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:graphview/GraphView.dart';
import 'dart:math';

class Referral extends StatefulWidget {
  final String walletAddress = "0xYourWalletAddress";

  Referral({super.key});

  @override
  _ReferralState createState() => _ReferralState();
}

class _ReferralState extends State<Referral> with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final Graph _graph = Graph();
  final BuchheimWalkerConfiguration _builder = BuchheimWalkerConfiguration();
  final Map<String, bool> _loadedNodes = {};
  final Map<String, Offset> _nodePositions = {};
  final Map<String, GlobalKey> _nodeKeys = {};

  Offset? _interactiveViewerSize;
  Node? _selectedNode;
  bool isFirstNodeSelected = false;
  AnimationController? _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();

    final root = Node.Id(widget.walletAddress);
    _graph.addNode(root);
    _loadedNodes[root.key.toString()] = false;
    _nodeKeys[root.key.toString()] = GlobalKey();

    _builder
      ..siblingSeparation = 50
      ..levelSeparation = 100
      ..subtreeSeparation = 50
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _updateInteractiveViewerSize();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _updateInteractiveViewerSize() {
    // Update InteractiveViewer size dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        setState(() {
          _interactiveViewerSize =
              Offset(renderBox.size.width, renderBox.size.height);
        });
      }

      if (!isFirstNodeSelected) {
        _animateToNode(Node.Id(widget.walletAddress));
      } else {
        if (_selectedNode != null) _animateToNode(_selectedNode!);
      }

      print("-Updated InteractiveViewer size: $_interactiveViewerSize");
    });
  }

  List<String> _getChildren(String parentAddress) {
    final Random random = Random();
    final int numChildren = random.nextInt(4) + 1;

    return List<String>.generate(numChildren, (index) {
      final randomPart = random.nextInt(100000).toString().padLeft(5, '0');
      return "$parentAddress-$randomPart";
    });
  }

  void _addChildNodes(String parentKey, Node parentNode) {
    final List<String> children = _getChildren(parentKey);
    for (final String childAddress in children) {
      final Node childNode = Node.Id(childAddress);
      if (!_graph.nodes.contains(childNode)) {
        _graph.addNode(childNode);
        _graph.addEdge(parentNode, childNode);
        _loadedNodes[childNode.key.toString()] = false;
        _nodeKeys[childNode.key.toString()] = GlobalKey();
      }
    }

    setState(() {
      _loadedNodes[parentKey] = true;
    });
  }

  void _animateToNode(Node node) {
    final String nodeKey = node.key.toString();
    final Offset? nodePosition = _nodePositions[nodeKey];

    if (nodePosition == null) {
      print("Position not found for node: $nodeKey");
      return;
    }

    final RenderBox? graphRenderBox = context.findRenderObject() as RenderBox?;
    if (graphRenderBox == null) {
      print("Graph RenderBox is null.");
      return;
    }

    final Offset screenSize = _interactiveViewerSize ?? const Offset(0, 0);
    final Offset screenCenter = Offset(screenSize.dx / 2, screenSize.dy / 2);

    final RenderBox? nodeRenderBox =
        _nodeKeys[nodeKey]?.currentContext?.findRenderObject() as RenderBox?;
    if (nodeRenderBox == null) {
      print("Node RenderBox is null for $nodeKey.");
      return;
    }

    final Size nodeSize = nodeRenderBox.size;
    final double currentScale =
        _transformationController.value.getMaxScaleOnAxis();
    final Offset targetTranslation = screenCenter -
        ((nodePosition + Offset(nodeSize.width / 2, nodeSize.height / 2)) *
            currentScale);

    final Matrix4 targetMatrix = Matrix4.identity()
      ..translate(targetTranslation.dx, targetTranslation.dy)
      ..scale(currentScale);

    _animationController?.removeListener(_onAnimationUpdate);
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _animationController!.addListener(_onAnimationUpdate);
    _animationController!.reset();
    _animationController!.forward();
  }

  void _onAnimationUpdate() {
    if (_animation != null) {
      _transformationController.value = _animation!.value;
    }
  }

  @override
  void didUpdateWidget(covariant Referral oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateInteractiveViewerSize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Referral Tree").tr(),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _selectedNode = null;
            _updateInteractiveViewerSize();
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Update InteractiveViewer size dynamically
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final newSize =
                  Offset(constraints.maxWidth, constraints.maxHeight);
              _interactiveViewerSize = newSize;

              if (!isFirstNodeSelected) {
                _animateToNode(Node.Id(widget.walletAddress));
              } else {
                if (_selectedNode != null) _animateToNode(_selectedNode!);
              }

              print("Updated InteractiveViewer size: $_interactiveViewerSize");
            });

            return InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(double.infinity),
              minScale: 0.5,
              maxScale: 2.0,
              transformationController: _transformationController,
              child: GraphView(
                graph: _graph,
                algorithm: BuchheimWalkerAlgorithm(
                  _builder,
                  TreeEdgeRenderer(_builder),
                ),
                builder: (Node node) {
                  return _buildNodeWidget(node);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNodeWidget(Node node) {
    final String nodeKey = node.key.toString();
    return LayoutBuilder(
      key: _nodeKeys[nodeKey],
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? nodeRenderBox = _nodeKeys[nodeKey]
              ?.currentContext
              ?.findRenderObject() as RenderBox?;
          final RenderBox? graphRenderBox =
              context.findAncestorRenderObjectOfType<RenderBox>();

          if (_nodeKeys[nodeKey] == null) {
            print("there is no noKey in the array for that node: $nodeKey");
            return;
          }

          if (nodeRenderBox == null) {
            print("nodeRenderBox is null for node id: $nodeKey");
            return;
          }

          if (graphRenderBox == null) {
            print("graphRenderBox is null for node id: $nodeKey");
            return;
          }

          final Offset globalPosition =
              nodeRenderBox.localToGlobal(Offset.zero);
          final Offset localPosition =
              graphRenderBox.globalToLocal(globalPosition);
          final double currentScale =
              _transformationController.value.getMaxScaleOnAxis();
          final Offset adjustedPosition = localPosition / currentScale;

          _nodePositions[nodeKey] = adjustedPosition;

          print("Updated position (node id: $nodeKey): $adjustedPosition");
        });

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedNode = node;
              isFirstNodeSelected = true;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 50,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _selectedNode == node ? Colors.red : Colors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    nodeKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    if (!(_loadedNodes[nodeKey] ?? false)) {
                      _addChildNodes(nodeKey, node);
                      _updateInteractiveViewerSize();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Children already loaded.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
