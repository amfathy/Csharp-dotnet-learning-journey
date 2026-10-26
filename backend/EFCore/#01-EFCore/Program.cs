namespace Efcore
{
    internal class Program
    {
        static void Main(string[] args)
        {
            //display wallet table 
            using (var context = new AppDbContext())
            {
                foreach (var wallet1 in context.Wallets)
                {
                    //Console.WriteLine(wallet1);
                }
            }

            //retrieve item with id 2 
            using (var context = new AppDbContext())
            {
                var item = context.Wallets.FirstOrDefault(x => x.Id == 2 );
                //Console.WriteLine(item);
            }

            //insert data inside wallet 
            var wallet = new Wallet()
            {
                Holder = "Fathy",
                Balance = 55000M
            };
            using (var context = new AppDbContext())
            {
                //context.Wallets.Add(wallet);
               // context.SaveChanges();
            }


            //update specifc column 
            using ( var context = new AppDbContext())
            {
                var wallet4 = context.Wallets.Single(x => x.Id == 4 );
                wallet4.Balance += 1000; 

                context.SaveChanges();  
            }

            //delete specific row 
            using (var context = new AppDbContext())
            {
               // var wallet5 = context.Wallets.Single(x => x.Id == 2);

               // context.Remove(wallet5); 
               // context.SaveChanges();   
            }

            using (var context = new AppDbContext())
            {
                var wallet6 = context.Wallets.Where(x => x.Balance > 5000); 
                foreach (var walle in wallet6)
                {
                  //  Console.WriteLine(walle);   
                }
               
            }

            //transfer amount from accout with id 1 to account iwth id 2 
            using (var context = new AppDbContext())
            {
                using (var transaction = context.Database.BeginTransaction())
                {
                    var emp1 = context.Wallets.Single(x => x.Id == 1);
                    var emp2 = context.Wallets.Single(x => x.Id == 2);
                   
                    var TransferAmount = 500;
                   
                    emp1.Balance -= TransferAmount;
                    context.SaveChanges();

                    emp2.Balance += TransferAmount;
                    context.SaveChanges(); 

                    transaction.Commit();   
                }
            }
        }
    }
}
