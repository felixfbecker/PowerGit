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

using System.Collections.Generic;
using System.Linq;
using LibGit2Sharp;

namespace GitAutomationCore
{
	public sealed class CommitInfo
	{
		public CommitInfo(Commit commit)
		{
			Author = commit.Author;
			Committer = commit.Committer;
			Encoding = commit.Encoding;
			Id = commit.Id;
			Message = commit.Message;
			MessageShort = commit.MessageShort;
			Notes = new List<Note>(commit.Notes).ToArray();

			Parents = new ObjectId[commit.Parents.Count()];
			var idx = 0;
			foreach( var parent in commit.Parents)
			{
				Parents[idx] = parent.Id;
				++idx;
			}
		}

		public Signature Author { get; private set; }
		public Signature Committer { get; private set; }
		public string Encoding { get; private set; }
		public ObjectId Id { get; private set; }
		public string Message { get; private set; }
		public string MessageShort { get; private set; }
		public Note[] Notes { get; private set; }
		public ObjectId[] Parents { get; private set; }

		public string Sha
		{
			get { return Id.Sha; }
		}
	}
}
