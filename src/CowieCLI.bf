using System;
using System.Collections;
using System.Reflection;

namespace CowieCLI
{
	/*
	Option types:
		Short flag option (bool): -q -> bool quiet = true (false if option is not present)
		Verbose flag option (bool): --quiet -> bool quiet = true (false if option is not present)
		Option with value (String): --letters abc -> String letters = "abc" (Empty string if option is not present)
		Option with multiple values (List<String>): --letters a b c -> List<String> letters = { "a", "b", "c" } (Empty list if option is not present)
	*/
	public class CowieCLI
	{
		public String Name = new .() ~ delete(_);
		public String Description = new .() ~ delete(_);
		public List<CommandEntry> Commands = new .() ~ DeleteContainerAndItems!(_);
		public static Verbosity CurrentVerbosity = .Normal;

		private String mInvalidArgument = new .() ~ delete _;

		public this(String name, String description)
		{
			Name.Set(name);
			Description.Set(description);
		}

		public  void RegisterCommand<T>(StringView name) where T : ICommand
		{
			let entry = new CommandEntry(name, typeof(T));
			Commands.Add(entry);
		}

		public int Run(Span<String> args)
		{
			if ((args.Length == 0) || args[0].Equals("--help") || args[0].Equals("-h"))
			{
				Help();
				return 0;
			}

			let commandRes = GetCommand(args[0]);

			if (commandRes == .Err)
			{
				CowieCLI.Error("Command {} not found.", args[0]);
				return 1;
			}

			if (args[1].Equals("--help") || args[1].Equals("-h"))
			{
				Help(commandRes.Value);
				delete commandRes.Value;
				return 0;
			}

			let command = commandRes.Value;
			let commandCall = ParseCommand(args, command);
			if (commandCall == .Err)
			{
				CowieCLI.Error("Invalid argument: {}", mInvalidArgument);
				Help();
				delete command;
				return 1;
			}

			if (PopulateCommand(command, commandCall) case .Err)
			{
				CowieCLI.Error("Couldn't populate the command");
				delete commandCall.Value;
				delete command;
				return 2;
			}

			let res = command.Execute();

			delete commandCall.Value;
			delete command;

			return res;
		}

		public void Help(ICommand command = null)
		{
			if (command != null)
			{
				command.Help(Name);
			}
			else
			{
				Console.WriteLine(Name);
				Console.WriteLine(Description);
				Console.WriteLine("Usage: {} <command> [<args>] [options...]", Name);
				Console.WriteLine("\nList of available commands:");

				for (var entry in Commands)
				{
					var com = entry.Instantiate();
					Console.WriteLine("  - {}\t\t{}", com.Info.Name, com.Info.About);
					delete com;
				}

				Console.WriteLine("\nSee {} <command> [--help | -h] for specific command help", Name);
			}
		}

		private Result<void> PopulateCommand(ICommand command, CommandCall call)
		{
			for (let option in command.Info.Options)
			{
				var optionName = scope String(option.Name);

				if (!option.IsOptional && !call.HasOption(optionName))
				{
					CowieCLI.Error("Argument {} is required.", optionName);
					return .Err;
				}

				if (!call.HasOption(optionName))
				{
					continue;
				}

				String.Capitalized(optionName);
				var tempField = command.GetType().GetField(optionName);
				var tempProp = command.GetType().GetProperty(optionName);

				if ((tempField == .Err) && (tempProp == .Err))
				{
					CowieCLI.Error("Command {} has no field or property {}", option.Name, optionName);
					return .Err;
				}

				var field = (tempField != .Err) ? (tempField.Value) : (
					(tempProp != .Err) ? (tempProp.Value) : (default(FieldInfo))
				);

				if (field == default(FieldInfo))
				{
					CowieCLI.Error("Setting field {} failed", optionName);
					return .Err;
				}

				if (PopulateField(command, field, option, call.GetValues(option.Name)) case .Err)
				{
					CowieCLI.Error("Setting field {} failed", optionName);
					return .Err;
				}
			}
			return .Ok;
		}

		private Result<void> PopulateField(ICommand command, FieldInfo field, CommandOption option, List<String> values)
		{
			if (option.IsList)
			{
				return PopulateListField(command, field, values);
			}

			var res = Result<void, FieldInfo.Error>();
			switch (field.FieldType)
			{
			case typeof(String):
				res = field.SetValue(command, values[0]);
				break;
			case typeof(int):
				var value = Int.Parse(values[0]);
				res = field.SetValue(command, value);
				break;
			case typeof(float):
				var value = Float.Parse(values[0]);
				res = field.SetValue(command, value);
				break;
			case typeof(bool):
				var value = Boolean.Parse(values[0]).Value;
				res = field.SetValue(command, value);
				break;
			default:
				CowieCLI.Error("Unsupported type: {}", field.FieldType);
				return .Err;
			}

			if (res != .Ok)
			{
				CowieCLI.Error("Error setting field {}.", field.Name);
				return .Err;
			}

			return .Ok;
		}

		private Result<void> PopulateListField(ICommand command, FieldInfo field, List<String> values)
		{
			var listType = field.FieldType as SpecializedGenericType;
			var paramType = listType.GetGenericArg(0);

			var fieldRef = field.GetValue(command).Value.Get<Object>();
			var addMethod = fieldRef.GetType().GetMethod("Add");

			switch (addMethod)
			{
			case .Err(let err):
				CowieCLI.Error("Cannot find method Add on field {}", field.Name);
				return .Err;
			default:
				break;
			}

			var res = Result<Variant, MethodInfo.CallError>();
			for (var value in values)
			{
				switch (paramType)
				{
				case typeof(String):
					res = addMethod.Get().Invoke(fieldRef, new String(value));
					break;
				case typeof(int):
					var val = Int.Parse(value);
					res = addMethod.Get().Invoke(fieldRef, val);
					break;
				case typeof(float):
					var val = Float.Parse(value);
					res = addMethod.Get().Invoke(fieldRef, val);
					break;
				case typeof(bool):
					var val = Boolean.Parse(value);
					res = addMethod.Get().Invoke(fieldRef, val);
					break;
				default:
					CowieCLI.Error("Unsupported type: {}", field.FieldType);
					return .Err;
				}

				switch (res)
				{
				case .Err(let err):
					CowieCLI.Error("Error setting field {}.", field.Name);
					return .Err;
				case .Ok(let val):
					break;
				}
			}

			return .Ok;
		}

		private Result<CommandCall> ParseCommand(Span<String> args, ICommand command)
		{
			var call = new CommandCall();
			var validArg = true;
			var optionsParsed = 0;

			// We start as 1 because 0 is the name of the command that should have been parsed
			// prior to arriving here.
			for (int i = 1; i < args.Length; i++)
			{
				var arg = args[i];
				var namedArg = scope String();
				if (!command.HasNamedOption(arg))
				{
					validArg = false;
				}
				else
				{
					namedArg.Set(arg);
					int count = 0;
					for (int j = 0; j < arg.Length; j++)
					{
						if (arg[j] != '-')
							break;
						count++;
					}
					validArg = true;

					namedArg.Remove(0, count);
				}

				if (!validArg && arg.StartsWith('-'))
				{
					mInvalidArgument.Set(arg);
					delete call;
					return .Err;
				}

				if ((optionsParsed >= command.Info.RequiredOptions) && !validArg)
				{
					mInvalidArgument.Set(arg);
					delete call;
					return .Err;
				}
				else
				{
					var values = scope List<String>();
					CommandOption option = default;

					if (namedArg.IsEmpty)
					{
						option = command.Info.Options[optionsParsed++];
						if (ParseArguments(args, ref i, option, values) case .Err)
						{
							CowieCLI.Error("Cannot parse arguments for option: {}", arg);
							mInvalidArgument.Set(arg);
							ClearAndDeleteItems(values);
							delete call;
							return .Err;
						}
					}
					else
					{
						option = command.Info.GetNamedOption(namedArg);

						if (!option.IsFlag)
							i++;
						if (ParseArguments(args, ref i, option, values) case .Err)
						{
							CowieCLI.Error("Cannot parse arguments for option: {}", arg);
							mInvalidArgument.Set(arg);
							ClearAndDeleteItems(values);
							delete call;
							return .Err;
						}
					}

					call.AddOption(option.Name, values);
				}
			}

			return call;
		}

		private Result<void> ParseArguments(Span<String> args, ref int idx, CommandOption option, List<String> values)
		{
			if (option.IsList && !option.CharSep.IsWhiteSpace)
			{
				var arg = args[idx];
				if (!arg.Contains(option.CharSep))
				{
					return .Err;
				}

				var vals = arg.Split(option.CharSep);
				for (var v in vals)
				{
					values.Add(new String(v));
				}
			}
			else if (option.IsList && option.CharSep.IsWhiteSpace)
			{
				for (; idx < args.Length; idx++)
				{
					var arg = args[idx];
					if (arg.StartsWith('-'))
					{
						// We want to parse from this argument in the next pass.
						idx--;
						break;
					}

					values.Add(new String(arg));
				}
			}
			else
			{
				ParseArgument(args[idx], option, values);
			}

			return .Ok;
		}

		private Result<void> ParseArgument(String arg, CommandOption option, List<String> values)
		{
			if (option.IsFlag)
			{
				values.Add(new String(Boolean.TrueString));
			}
			else
			{
			 	values.Add(new String(arg));
			}

			return .Ok;
		}

		private Result<ICommand> GetCommand(StringView name)
		{
			for (var entry in Commands)
			{
				if (entry.Name == name)
					return entry.Instantiate();
			}

			return .Err;
		}

		public  bool IsCommand(StringView name)
		{
			for (var entry in Commands)
				if (entry.Name == name)
					return true;
			return false;
		}

		public  bool Ask(StringView text)
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
