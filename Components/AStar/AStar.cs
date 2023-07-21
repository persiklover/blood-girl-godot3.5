using Godot;
using System;
using System.Collections.Generic;

public class AStar : Node2D {
  private Grid grid;

  // Called when the node enters the scene tree for the first time.
  public override void _Ready() {
    grid = (Grid)GetChild(0);
  }

  // Called every frame. 'delta' is the elapsed time since the previous frame.
  public List<Vector2> FindPath(Vector2 from, Vector2 to) {
    // Debugging
    var startTime = OS.GetTicksMsec();

    // grid.Reset();

    var startNode = grid.GetNodeAt(from);
    if (startNode == null || !startNode.walkable) {
      GD.Print("Start point is not walkable!");
      return null;
    }

    var endNode = grid.GetNodeAt(to);
    if (endNode == null || !endNode.walkable) {
      GD.Print("End point is not walkable!");
      return null;
    }

    var open_list   = new List<GridNode>();
    var closed_list = new List<GridNode>();
    open_list.Add(startNode);

    const int MAX_ITERATIONS = 1_000;
    int step = 0;
    while (open_list.Count > 0) {
      step += 1;
      if (step > MAX_ITERATIONS) return null;

      var current_node = open_list[0];
      foreach (GridNode open_node in open_list) {
        if (
          open_node.fCost < current_node.fCost ||
          (open_node.fCost == current_node.fCost && open_node.hCost < current_node.hCost)
        ) {
          current_node = open_node;
        }
      }

      open_list.Remove(current_node);
      closed_list.Add(current_node);

      if (current_node == endNode) {
        var path = new List<Vector2>();
        var parent = current_node.parent;
        while (parent != null) {
          path.Insert(0, parent.globalPosition);
          parent = parent.parent;
        }
        // path.RemoveAt(0);
        return path;
      }

      // Проходимся по всем соседним клеткам
      int[] adjacent_nodes = {};
      int[] numbers = { -1, 0, 1 };
      foreach (int i in numbers) {
        foreach (int j in numbers) {
          // Не проверяем текущую клетку
          if (i == 0 && j == 0) continue;

          var x = current_node.x + i;
          var y = current_node.y + j;
          var neighbour = grid.At(x, y);
          if (neighbour == null) continue;

          if (!neighbour.walkable || closed_list.Contains(neighbour)) {
            continue;
          }

          var movement_cost_to_neighbour = current_node.gCost + current_node.DisranceTo(neighbour);
          if (movement_cost_to_neighbour < neighbour.gCost || !open_list.Contains(neighbour)) {
            neighbour.gCost = movement_cost_to_neighbour;
            neighbour.hCost = neighbour.DisranceTo(endNode);
            neighbour.parent = current_node;
            
            if (!open_list.Contains(neighbour)) {
              open_list.Add(neighbour);
            }
          }
        }
      }
    }
    return null;
  }
}
