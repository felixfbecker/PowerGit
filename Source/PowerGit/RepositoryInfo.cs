// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using LibGit2Sharp;

namespace GitAutomationCore
{
	public sealed class RepositoryInfo
	{
		public RepositoryInfo(RepositoryInformation information)
		{
			Path = information.Path;
			WorkingDirectory = information.WorkingDirectory;
			IsBare = information.IsBare;
			IsShallow = information.IsShallow;
		}

		public string Path { get; private set; }
		public string WorkingDirectory { get; private set; }
		public bool IsBare { get; private set; }
		public bool IsShallow { get; private set; }
	}
}
