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

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibGit2Sharp;

namespace PowerGit
{
    public sealed class MergeResult
    {
        public MergeResult(LibGit2Sharp.MergeResult result)
        {
            if( result.Commit != null )
            {
                Commit = new CommitInfo(result.Commit);
            }

            Status = result.Status;

        }

        public MergeStatus Status { get; private set; }

        public CommitInfo Commit { get; private set; }
    }
}
