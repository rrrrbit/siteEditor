#if TOOLS
using Godot;
using System;

[Tool]
public partial class editor : EditorScript
{
	// Called when the script is executed (using File -> Run in Script Editor).
	public override void _Run()
	{
		GD.Print("hi were in the editor");
	}
}
#endif
