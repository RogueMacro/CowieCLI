using System;
using System.Collections;
using System.Reflection;

namespace CowieCLI
{
	public static class CowieCLI
	{
		public static List<CommandEntry> Commands = new .() ~ DeleteContainerAndItems!(_);

		public static Verbosity CurrentVerbosity = .Normal;

		public static String HelpMessage;
		public static Type DefaultCommand = null;

		public static void Init(String helpMessage = "")
		{
			HelpMessage = helpMessage;
		}

		public static void Init<TDefaultCommand>(String helpMessage = "") where TDefaultCommand : ICommand
		{
			DefaultCommand = typeof(TDefaultCommand);
			Init(helpMessage);
		}

		public static void Help(ICommand command = null)
		{
			if (command == null)
				Console.WriteLine(HelpMessage);
			else
				Console.WriteLine(command.Info.About);
		}

		public static void Run(Span<String> args)
		{
			List<CommandCall> calls = scope .();
			CommandCall commandCall = scope .();

			// TODO: Implement multiple command
			// List<StringView> extraCommands = null;

			for (var arg in args)
			{
				// Option
				if (arg.StartsWith('-')) 
				{
					commandCall.AddOption(arg);
				}
				// Command
				else if (IsCommand(arg))
				{
					if (calls.Count > 0)
					{
						calls.Add(commandCall);
						commandCall = scope:: .();
					}

					commandCall.Command.Set(arg);
				}
				// Multiple command calls (same options). Example: > install+add mypackage --verbose
				/*else if (IsMultiCommand(arg))
				{
					extraCommands = scope:: .();
					for (let command in arg.Split('+'))
						extraCommands.Add(command);
				}*/
				else if (commandCall.Command.IsEmpty)
				{
					FatalError("Unknown command: {}", arg);
				}
				// Option value
				else
				{
					commandCall.AddOption(arg);
				}
			}

			calls.Add(commandCall);

			// No commands called
			if (calls.IsEmpty)
			{
				Help();
				return;
			}

			for (let call in calls)
			{
				let result = GetCommand(call.Command);
				if (result case .Ok(let commandInstance))
				{
					if (commandInstance == null)
						continue;

					RunCommand(commandInstance, call.Options);
					delete commandInstance;
				}
				else
					FatalError("Unknown command: {}", call.Command);
			}	

			bool IsMultiCommand(StringView arg)
			{
				for (var char in arg)
					if (!char.IsLetter && char != '+')
						return false;
				return true;
			}
		}

		private static void RunCommand(ICommand command, List<String> options)
		{
			CurrentVerbosity = .Normal;

			for (let option in options)
			{
				switch (option)
				{
				case "--debug", "-d":
					CurrentVerbosity = .Debug;
					options.DeleteAndRemove(option);
					break;
				case "--verbose", "-v":
					CurrentVerbosity = .Verbose;
					options.DeleteAndRemove(option);
					break;
				case "--quiet", "-q":
					CurrentVerbosity = .Quiet;
					options.DeleteAndRemove(option);
					break;
				}
			}

			for (let option in command.Info.Options)
			{
				var fieldResult = GetField(option.Name);
				if (fieldResult case .Ok(let field))
				{
					switch (field.FieldType)
					{
					case typeof(String):
						var actualOption = GetStringOption(option.Name, option.Short);
						if (actualOption == "" && option.IsRequired)
							FatalError("Option {} is required", option);

						field.SetValue(command, actualOption);
						break;
					case typeof(List<String>):
						var optionValues = GetMultipleOptions(option.Name, option.Short);
						if (optionValues.Count == 0 && option.IsRequired)
							FatalError("Option {} is required", option);

						field.SetValue(command, optionValues);
						for (var value in optionValues)
							options.Remove(value);
						break;
					case typeof(bool):
						field.SetValue(command, GetOption(option.Name, option.Short));
						break;
					default:
						var typename = scope String();
						field.FieldType.GetName(typename);
						FatalError("Command option field '{}' has invalid type: {}", field.Name, typename);
					}

					RemoveOption(option.Name, option.Short);
				}
				else
					FatalError("Could not find field matching option: {}", option);
			}

			if (options.Count == 1)
				FatalError("Unknown option: {}", options[0]);
			else if (options.Count > 1)
			{
				var str = scope String()..Join(", ", options.GetEnumerator());
				FatalError("Unknown options: {}", str);
			}

			// Check requirements and conflicts
			for (let optionToCheck in command.Info.Options)
			{
				for (let option in command.Info.Options)
				{
					if (option == optionToCheck)
						continue;

					var field = GetField(option.Name).Get(); // Has already been proven in previous loop that it exists
					
					switch (field.FieldType)
					{
					case typeof(String):
						field.GetValue<String>(command, var value);

						if (value == "")
							CheckRequirement();

						if (value != "")
							CheckConflict();

						break;
					case typeof(List<String>):
						field.GetValue<List<String>>(command, var value);

						if (value.Count == 0)
							CheckRequirement();

						if (value.Count > 0)
							CheckConflict();

						break;
					case typeof(bool):
						field.GetValue<bool>(command, var value);

						if (!value)
							CheckRequirement();

						if (value)
							CheckConflict();

						break;
					}
				}
			}

			command.Execute();

			void CheckRequirement()
			{
				if (optionToCheck.Requirements.Contains(option.Name))
					FatalError("Option {} requires the {} option", optionToCheck, option);
			}

			void CheckConflict()
			{
				if (optionToCheck.Conflicts.Contains(option.Name))
					FatalError("Option {} conflicts with the {} option", optionToCheck, option);
			}	

			void RemoveOption(String verbose, String short)
			{
				for (var option in options)
				{
					if (IsOption(option, verbose, short))
					{
						options.DeleteAndRemove(option);
						break;
					}
				}
			}

			Result<FieldInfo> GetField(StringView name)
			{
				for (var field in command.GetType().GetFields())
					if (String.Compare(field.Name, name, true))
						return field;
				return .Err;
			}

			bool GetOption(String verbose, String short = "")
			{
				for (var option in options)
				{
					if (IsOption(option, verbose, short))
						return true;
				}

				return false;
			}

			String GetStringOption(String verbose, String short = "")
			{
				var str = new String();
				var enumerator = options.GetEnumerator();
				for (var option in enumerator)
				{
					if (IsOption(option, verbose, short))
					{
						if (enumerator.GetNext() case .Ok(let nextOption))
							str.Set(nextOption);
						else
							FatalError("Option {} has no value", option);
					}
				}

				return str;
			}

			List<String> GetMultipleOptions(String verbose, String short = "")
			{
				var enumerator = options.GetEnumerator();
				var isOption = false;
				var containsOption = options.Contains(verbose) || options.Contains(short);
				var result = new List<String>();

				for (var option in enumerator)
				{
					if (!isOption)
					{
						if ((!containsOption && !option.StartsWith('-')) ||
							(containsOption && IsOption(option, verbose, short)))
							isOption = true;
						else
							continue;
					}
					
					if (option.StartsWith('-'))
						break;

					result.Add(option);
				}

				return result;
			}

			bool IsOption(String option, String verbose, String short = "")
			{
				if ((option.Length >= 3 && StringView(option, 2) == verbose) ||
					(option.Length >= 2 && StringView(option, 1) == short))
					return true;
				return false;
			}
		}

		public static bool IsCommand(StringView name)
		{
			for (var entry in Commands)
				if (entry.Name == name)
					return true;
			return false;
		}

		public static Result<ICommand> GetCommand(StringView name)
		{
			for (var entry in Commands)
			{
				if (entry.Name == name)
					return entry.Instantiate();
			}

			return .Err;
		}

		public static void RegisterCommand<T>(StringView name) where T : ICommand
		{
			let entry = new CommandEntry(name, typeof(T));
			Commands.Add(entry);
		}

		public static bool Ask(StringView text)
		{
			bool DoAsk()
			{
				while (true)
				{
					Console.Write("{} [y/n] ", text);
					let char = Console.ReadKey();
					if (char == 'y')
						return true;
					else if (char == 'n')
						return false;
				}
			}

			bool answer = DoAsk();
			let length = 19 + text.Length;
			Console.EmptyLine(length);
			return answer;
		}

		public static void Success(StringView fmt, params Object[] args) => Print(.Green, true, scope String()..AppendF("[Success] {}", fmt), params args);
		public static void Info(StringView fmt, params Object[] args) => Print(.Cyan, true, scope String()..AppendF("[Info] {}", fmt), params args);
		public static void Warning(StringView fmt, params Object[] args) => Print(.Yellow, true, scope String()..AppendF("[Warning] {}", fmt), params args);
		public static void Error(StringView fmt, params Object[] args) => Print(.Red, true, scope String()..AppendF("[Error] {}", fmt), params args);
		public static void FatalError(StringView fmt, params Object[] args)
		{
			Error(fmt, params args);
#if DEBUG
			Console.Write("Press any key to exit...");
			Console.ReadKey();
#endif
			Internal.FatalError(scope String()..AppendF(fmt, params args));
		}

		public static void Print(bool newline, String fmt, params Object[] args) => Print(.White, newline, fmt, params args);
		public static void Print(ConsoleColor color, bool newline, String fmt, params Object[] args)
		{
			if (CurrentVerbosity == .Quiet)
				return;

			let origin = Console.ForegroundColor;
			Console.ForegroundColor = color;

			Console.Write(fmt, params args);
			if (newline)
				Console.WriteLine();

			Console.ForegroundColor = origin;
		}
	}
}
