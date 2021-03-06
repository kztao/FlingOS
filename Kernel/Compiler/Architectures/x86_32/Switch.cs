﻿#region LICENSE
// ---------------------------------- LICENSE ---------------------------------- //
//
//    Fling OS - The educational operating system
//    Copyright (C) 2015 Edward Nutting
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 2 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Project owner: 
//		Email: edwardnutting@outlook.com
//		For paper mail address, please contact via email for details.
//
// ------------------------------------------------------------------------------ //
#endregion
    
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Kernel.Compiler.Architectures.x86_32
{
    /// <summary>
    /// See base class documentation.
    /// </summary>
    public class Switch : ILOps.Switch
    {
        /// <summary>
        /// See base class documentation.
        /// </summary>
        /// <param name="anILOpInfo">See base class documentation.</param>
        /// <param name="aScannerState">See base class documentation.</param>
        /// <returns>See base class documentation.</returns>
        /// <exception cref="System.NotSupportedException">
        /// Thrown if divide operands are floating point numbers or if attempting to divide 64-bit numbers.
        /// </exception>
        /// <exception cref="System.InvalidOperationException">
        /// Thrown if either operand is &lt; 4 bytes long.
        /// </exception>
        public override string Convert(ILOpInfo anILOpInfo, ILScannerState aScannerState)
        {
            StringBuilder result = new StringBuilder();

            StackItem testItem = aScannerState.CurrentStackFrame.Stack.Pop();

            if (testItem.isFloat)
            {
                //TODO - Support floats
                throw new NotSupportedException("Switch for floats no supported!");
            }
            else if (testItem.sizeOnStackInBytes != 4)
            {
                //TODO - Support other sizes
                throw new NotSupportedException("Switch for non-int32s not supported!");
            }

            result.AppendLine("pop dword eax");
            for (int i = 0; i < anILOpInfo.ValueBytes.Length / 4; i++)
            {
                int branchPos = anILOpInfo.Position + 4 + Utils.ReadInt32(anILOpInfo.ValueBytes, i * 4);
                branchPos += anILOpInfo.ValueBytes.Length;
                branchPos += 1;

                result.AppendLine("cmp eax, " + i);
                string jumpToLabel = string.Format("{0}.IL_{1}_0", 
                    aScannerState.GetMethodID(aScannerState.CurrentILChunk.Method),
                    branchPos);
                result.AppendLine("je " + jumpToLabel);
            }

            return result.ToString().Trim();
        }
    }
}
