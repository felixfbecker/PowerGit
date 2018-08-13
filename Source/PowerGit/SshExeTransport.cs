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
using System.IO;
using LibGit2Sharp;

namespace PowerGit
{
	public class SshExeTransport : SmartSubtransport
	{
		public static string ExePath { get; set; }
		private SshExeTransportStream _stream;

		private static SmartSubtransportRegistration<SshExeTransport> _registration;

		public static void Register(string pathToSsh)
		{
			if (_registration != null)
			{
				return;
			}

			if (!File.Exists(pathToSsh))
			{
				throw new ArgumentException("SSH at path {0} not found.", pathToSsh);
			}

			ExePath = pathToSsh;
			_registration = GlobalSettings.RegisterSmartSubtransport<SshExeTransport>("ssh");
		}

		public static void Unregister()
		{
			if (_registration == null)
				return;

			GlobalSettings.UnregisterSmartSubtransport(_registration);
			_registration = null;
		}


		protected override SmartSubtransportStream Action(string url, GitSmartSubtransportAction action)
		{
			switch (action)
			{
					// Both of these mean we're starting a new connection
				case GitSmartSubtransportAction.UploadPackList:
					_stream = new SshExeTransportStream(this, url, "git-upload-pack");
					break;
				case GitSmartSubtransportAction.ReceivePackList:
					_stream = new SshExeTransportStream(this, url, "git-receive-pack");
					break;
				case GitSmartSubtransportAction.UploadPack:
				case GitSmartSubtransportAction.ReceivePack:
					break;
				default:
					throw new InvalidOperationException("Invalid action for subtransport");
			}

			return _stream;
		}

		protected override void Close()
		{
			base.Close();

			if (_stream != null)
			{
				_stream.Dispose();
				_stream = null;
			}
		}

		protected override void Dispose()
		{
			base.Dispose();

			Close();
		}
	}
}
