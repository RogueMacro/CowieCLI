using System.Reflection;

namespace System.Reflection
{
	static
	{
		public static Result<FieldInfo> GetProperty(this TypeInstance type, String fieldName)
		{
			var name = scope String("prop__");
			name.Append(fieldName);

			for (int32 i = 0; i < type.[Friend]mFieldDataCount; i++)
			{
			    TypeInstance.FieldData* fieldData = &type.[Friend]mFieldDataPtr[i];
			    if (fieldData.[Friend]mName == name)
			        return FieldInfo(type, fieldData);
			}
			return .Err;
		}
	}
}
