using System;

namespace CowieCLI
{
	public abstract class ICommand
	{
		public abstract CommandInfo Info { get; }

		public abstract void Execute();
	}
}
