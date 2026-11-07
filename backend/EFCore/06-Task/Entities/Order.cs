using System;
using System.Collections.Generic;
using System.Text;

namespace ShopManagementSystem.Models
{
    internal class Order
    {
        public int Id { get; set; }
        public string?  CustomerEmail { get; set; }
        public DateTime OrderDate { get; set; }


        //Navigation Properties
        public ICollection<OrderDetail> OrderDetails { get; set; }
        = new List<OrderDetail>();
    }
}
