using System;
using CowieCLI;
using CowieCLITests.Commands;

namespace CowieCLITests
{
	class Program
	{
		public static void Main(String[] args)
		{
			var cli = scope CowieCLI();
			cli.Init("Help: Tests for the CowieCLI library.");
			cli.RegisterCommand<InitCommand>("init");
			cli.RegisterCommand<InstallCommand>("install");
			cli.Run(args);
		}
	}
}
