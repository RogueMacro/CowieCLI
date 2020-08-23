using System;
using System.Collections;

namespace CowieCLI
{
	public class CommandOption
	{
		public String Name = new .() ~ delete _;
		public String ShortName = new .() ~ delete _;
		public String Description = new .() ~ delete _;

		public bool IsOptional = false;
		public bool IsList = false;

		public List<String> Requirements = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Conflicts = new .() ~ DeleteContainerAndItems!(_);

		public this(StringView name, StringView description)
		{
			Name.Set(name);
			Description.Set(description);
		}

		public Self Optional()
		{
			IsOptional = true;
			return this;
		}

		public Self List()
		{
			IsList = true;
			return this;
		}

		public Self Short(StringView short)
		{
			ShortName.Set(short);
			return this;
		}

		public Self ConflictsWith(params StringView[] conflicts)
		{
			for (let conflict in conflicts)
				Conflicts.Add(new String(conflict));
			return this;
		}

		public Self Requires(params StringView[] requires)
		{
			for (let require in requires)
				Requirements.Add(new String(require));
			return this;
		}

		public override void ToString(String strBuffer)
		{
			strBuffer.Append(Name);
		}
	}
}
