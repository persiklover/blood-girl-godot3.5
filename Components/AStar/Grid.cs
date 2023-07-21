using Godot;
using System;
using System.Linq;

public class GridNode
{
  public int x;
  public int y;

  public Vector2 globalPosition;
  public bool walkable = true;
  public GridNode parent;

  public float gCost;
  public float hCost;
  public float fCost
  {
    get => gCost + hCost;
    set
    {
      fCost = value;
    }
  }

  public GridNode(int _x, int _y)
  {
    x = _x;
    y = _y;
  }

  public void Clear()
  {
    walkable = true;
    parent = null;
    gCost = 0;
    hCost = 0;
  }

  public float DisranceTo(GridNode node) {
		var diagonal_distance = new Vector2(0, 0).DistanceTo(new Vector2(Grid.SIZE, Grid.SIZE));
    var dist_x = Math.Abs(x - node.x);
    var dist_y = Math.Abs(y - node.y);
    if (dist_x > dist_y) {
			return diagonal_distance * dist_y + Grid.SIZE * (dist_x - dist_y);
    }
    return diagonal_distance * dist_x + Grid.SIZE * (dist_y - dist_x);
  }
}

[Tool]
public class Grid : Node2D {

  public static int SIZE = 16;

  [Export]
  public int ROWS = 50;

  [Export]
  public int COLS = 50;

  [Export]
  public int REFRESH_RATE_MS = 600;

  private Vector2 offset = new Vector2(SIZE / 2, SIZE / 2);

  private GridNode[,] grid;

  private ulong startTime = 999999999;

  // Called when the node enters the scene tree for the first time.
  public override void _Ready()
  {
    grid = new GridNode[ROWS, COLS];
    Reset();
    for (int x = 0; x < ROWS; x++)
    {
      for (int y = 0; y < COLS; y++)
      {
        Area2D area = new Area2D();
        area.Position = new Vector2(x * SIZE, y * SIZE) + offset;
        area.CollisionLayer = (uint)(Math.Pow(2, 1 - 1) + Math.Pow(2, 10 - 1));
        area.CollisionMask = (uint)(Math.Pow(2, 1 - 1) + Math.Pow(2, 10 - 1));

        RectangleShape2D shape = new RectangleShape2D();
        shape.Extents = new Vector2(SIZE / 2, SIZE / 2);

        CollisionShape2D collisionShape = new CollisionShape2D();
        collisionShape.Shape = shape;

        area.AddChild(collisionShape);

        AddChild(area);

        grid[x, y].globalPosition = area.GlobalPosition;
      }
    }
  }

  public void Reset() {
    for (int x = 0; x < ROWS; x++) {
      for (int y = 0; y < COLS; y++) {
        GridNode node = grid[x, y];
        if (node == null) {
          node = new GridNode(x, y);
          grid[x, y] = node;
        }
        node.Clear();
      }
    }
  }

  public GridNode At(int x, int y) {
    try {
      return grid[x, y];
    }
    catch (Exception e) {
      GD.PrintErr(e);
      return null;
    }
  }

  public GridNode GetNodeAt(Vector2 position) {
    for (int x = 0; x < ROWS; x++) {
      for (int y = 0; y < COLS; y++) {
        GridNode node = grid[x, y];
        if ((node != null) && (
          position.x >= node.globalPosition.x - SIZE / 2 &&
          position.x <= node.globalPosition.x + SIZE / 2 &&
          position.y >= node.globalPosition.y - SIZE / 2 &&
          position.y <= node.globalPosition.y + SIZE / 2
        )) {
          return node;
        }
      }
    }
    return null;
  }

  public override void _Process(float delta) {
    if (OS.GetSystemTimeMsecs() - startTime < (ulong)REFRESH_RATE_MS) {
      return;
    }

    startTime = OS.GetSystemTimeMsecs();
    Reset();

    string[] exception_groups = {
      "Enemy",
      "Player",
      "Bullet",
      "EnemyBullet"
    };
    foreach (Area2D area in GetChildren()) {
      var overlapping_bodies = area.GetOverlappingBodies();
      foreach (Node body in overlapping_bodies) {
        bool found = false;
        foreach (string group in exception_groups) {
          if (body.IsInGroup(group)) {
            found = true;
            break;
          }
        }

        if (found) {
          continue;
        }

        var x = (int)((area.Position - offset) / SIZE).x;
        var y = (int)((area.Position - offset) / SIZE).y;
        grid[x, y].walkable = false;
        break;
      }
    }

    if (GetTree().DebugCollisionsHint) {
      Update();
    }
  }

  public override void _Draw() {
    if (!GetTree().DebugCollisionsHint) return;

    for (int x = 0; x < ROWS; x++) {
      for (int y = 0; y < COLS; y++) {
        Color color = Colors.Gray;
        bool filled = false;

        GridNode node = grid[x, y];
        if (node == null) {
          DrawRect(new Rect2(x * SIZE, y * SIZE, SIZE, SIZE), color, filled);
          continue;
        }

        if (!node.walkable) {
          color = Colors.RebeccaPurple;
          filled = true;
        }
        DrawRect(new Rect2(x * SIZE, y * SIZE, SIZE, SIZE), color, filled);
      }
    }
  }
}
