using System;
using System.Collections;
using System.Reflection;
using CowieCLI;

namespace CowieCLITests.Commands
{
	[Reflect, AlwaysInclude(AssumeInstantiated=true, IncludeAllMethods=true)]
	public class InitCommand : ICommand
	{
		private CommandInfo mInfo = new CommandInfo()
			.Name("init")
			.About("Initialize the project")
			.Option(new CommandOption("name", "The name of the project."))
			.Option(
				new CommandOption("location", "The location of the project.")
					.Optional()
			)
			.Option(
				new CommandOption("flags", "Multiple flags.")
					.List(',')
					.Optional()
			) ~ delete (_);

		public override CommandInfo Info => mInfo;

		public String Name { get; set; }
		public String Location { get; set; }
		public List<String> Flags = new .() ~ DeleteContainerAndItems!(_);

		public override int Execute()
		{
			CowieCLI.Info("Init: Name = {}, Location = {}", Name, Location);

			if (!Flags.IsEmpty)
			{
				CowieCLI.Info("Flags:");
				for (var flag in Flags)
				{
					Console.WriteLine("\t{}", flag);
				}
				Console.WriteLine();
			}
			return 0;
		}
	}
}
