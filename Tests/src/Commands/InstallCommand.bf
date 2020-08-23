using System;
using System.Collections;
using System.Reflection;
using CowieCLI;

namespace CowieCLITests.Commands
{
	[Reflect, AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	public class InstallCommand : ICommand
	{
		private CommandInfo mInfo = new CommandInfo()
			.Name("install")
			.About("Install different packages.")
			.Option(
				new CommandOption("packages", "The list of packages to be installed.")
					.List()
			)
			.Option(
				new CommandOption("global", "Install the package globally.")
					.Short("g")
					.Flag()
					.Optional()
			) ~ delete (_);

		public override CommandInfo Info => mInfo;

		public List<String> Packages = new .() ~ DeleteContainerAndItems!(_);
		public bool Global;

		public override int Execute()
		{
			if (Packages.IsEmpty)
			{
				return 1;
			}

			CowieCLI.Info("Install packages: ");
			for (var package in Packages)
			{
				Console.Write("\t {}", package);
			}
			Console.WriteLine();
			CowieCLI.Info("Install globally: {}", Global);
			return 0;
		}
	}
}
