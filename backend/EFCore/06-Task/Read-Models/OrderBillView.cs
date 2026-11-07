using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Read_Models
{
    internal class OrderBillView
    {
        public int OrderId { get; set; }

        public string CustomerEmail { get; set; } = string.Empty;

        public decimal TotalAmount { get; set; }
    }
}
