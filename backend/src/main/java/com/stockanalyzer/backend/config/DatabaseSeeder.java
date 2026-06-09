package com.stockanalyzer.backend.config;

import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.service.YahooFinanceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseSeeder.class);

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private YahooFinanceService yahooFinanceService;

    @Override
    public void run(String... args) throws Exception {
        // If the database has outdated stock list (e.g. the original 8 stocks), clear and re-seed NIFTY 100
        if (stockRepository.count() < 50) {
            logger.info("Database contains outdated stock list (count={}). Clearing tables for NIFTY 100 seeding...", stockRepository.count());
            stockPriceRepository.deleteAll();
            stockRepository.deleteAll();
        }

        boolean seeded = false;
        if (stockRepository.count() == 0) {
            logger.info("No stocks found in database. Seeding NIFTY 100 stocks...");

            List<Stock> defaultStocks = Arrays.asList(
                new Stock("RELIANCE.NS", "Reliance Industries Limited", "NSE", "Energy", "Oil & Gas / Retail / Telecom"),
                new Stock("TCS.NS", "Tata Consultancy Services Limited", "NSE", "Technology", "IT Services"),
                new Stock("HDFCBANK.NS", "HDFC Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("INFY.NS", "Infosys Limited", "NSE", "Technology", "IT Services"),
                new Stock("ICICIBANK.NS", "ICICI Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("SBIN.NS", "State Bank of India", "NSE", "Financial Services", "Banking"),
                new Stock("BHARTIARTL.NS", "Bharti Airtel Limited", "NSE", "Telecommunication", "Telecom Services"),
                new Stock("ITC.NS", "ITC Limited", "NSE", "Consumer Goods", "Tobacco/Food/Hotels"),
                new Stock("LT.NS", "Larsen & Toubro Limited", "NSE", "Industrials", "Engineering & Construction"),
                new Stock("AXISBANK.NS", "Axis Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("KOTAKBANK.NS", "Kotak Mahindra Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("HINDUNILVR.NS", "Hindustan Unilever Limited", "NSE", "Consumer Goods", "FMCG"),
                new Stock("BAJFINANCE.NS", "Bajaj Finance Limited", "NSE", "Financial Services", "Non-Banking Financial Company"),
                new Stock("ASIANPAINT.NS", "Asian Paints Limited", "NSE", "Consumer Goods", "Paints"),
                new Stock("COALINDIA.NS", "Coal India Limited", "NSE", "Energy", "Mining & Minerals"),
                new Stock("M&M.NS", "Mahindra & Mahindra Limited", "NSE", "Automotive", "Passenger Vehicles / Tractors"),
                new Stock("TATASTEEL.NS", "Tata Steel Limited", "NSE", "Basic Materials", "Steel & Iron"),
                new Stock("ULTRACEMCO.NS", "UltraTech Cement Limited", "NSE", "Basic Materials", "Cement"),
                new Stock("NTPC.NS", "NTPC Limited", "NSE", "Utilities", "Power Generation"),
                new Stock("POWERGRID.NS", "Power Grid Corporation of India Limited", "NSE", "Utilities", "Power Transmission"),
                new Stock("SUNPHARMA.NS", "Sun Pharmaceutical Industries Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("TITAN.NS", "Titan Company Limited", "NSE", "Consumer Goods", "Jewellery & Watches"),
                new Stock("ADANIENT.NS", "Adani Enterprises Limited", "NSE", "Conglomerate", "Trading & Infrastructure"),
                new Stock("ONGC.NS", "Oil and Natural Gas Corporation Limited", "NSE", "Energy", "Oil & Gas Exploration"),
                new Stock("JSWSTEEL.NS", "JSW Steel Limited", "NSE", "Basic Materials", "Steel & Iron"),
                new Stock("TECHM.NS", "Tech Mahindra Limited", "NSE", "Technology", "IT Services"),
                new Stock("WIPRO.NS", "Wipro Limited", "NSE", "Technology", "IT Services"),
                new Stock("HCLTECH.NS", "HCL Technologies Limited", "NSE", "Technology", "IT Services"),
                new Stock("BAJAJFINSV.NS", "Bajaj Finserv Limited", "NSE", "Financial Services", "Insurance & Finance holding"),
                new Stock("GRASIM.NS", "Grasim Industries Limited", "NSE", "Basic Materials", "Textiles & Cement holding"),
                new Stock("CIPLA.NS", "Cipla Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("INDUSINDBK.NS", "IndusInd Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("TATACONSUM.NS", "Tata Consumer Products Limited", "NSE", "Consumer Goods", "FMCG / Tea & Coffee"),
                new Stock("NESTLEIND.NS", "Nestle India Limited", "NSE", "Consumer Goods", "FMCG / Food Products"),
                new Stock("SBILIFE.NS", "SBI Life Insurance Company Limited", "NSE", "Financial Services", "Life Insurance"),
                new Stock("DRREDDY.NS", "Dr. Reddy's Laboratories Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("HDFCLIFE.NS", "HDFC Life Insurance Company Limited", "NSE", "Financial Services", "Life Insurance"),
                new Stock("HINDALCO.NS", "Hindalco Industries Limited", "NSE", "Basic Materials", "Aluminium & Copper"),
                new Stock("BAJAJ-AUTO.NS", "Bajaj Auto Limited", "NSE", "Automotive", "Two & Three Wheelers"),
                new Stock("ADANIPORTS.NS", "Adani Ports and Special Economic Zone Limited", "NSE", "Industrials", "Port Operations"),
                new Stock("APOLLOHOSP.NS", "Apollo Hospitals Enterprise Limited", "NSE", "Healthcare", "Hospitals & Pharmacies"),
                new Stock("EICHERMOT.NS", "Eicher Motors Limited", "NSE", "Automotive", "Motorcycles / Commercial Vehicles"),
                new Stock("BPCL.NS", "Bharat Petroleum Corporation Limited", "NSE", "Energy", "Oil & Gas Refining"),
                new Stock("DIVISLAB.NS", "Divi's Laboratories Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("HEROMOTOCO.NS", "Hero MotoCorp Limited", "NSE", "Automotive", "Two Wheelers"),
                new Stock("BRITANNIA.NS", "Britannia Industries Limited", "NSE", "Consumer Goods", "Bakery & Food Products"),
                new Stock("SHRIRAMFIN.NS", "Shriram Finance Limited", "NSE", "Financial Services", "NBFC / Vehicle Finance"),
                new Stock("LICI.NS", "Life Insurance Corporation of India", "NSE", "Financial Services", "Life Insurance"),
                new Stock("HAL.NS", "Hindustan Aeronautics Limited", "NSE", "Industrials", "Aerospace & Defence"),
                new Stock("BEL.NS", "Bharat Electronics Limited", "NSE", "Industrials", "Defence Electronics"),
                new Stock("JIOFIN.NS", "Jio Financial Services Limited", "NSE", "Financial Services", "NBFC / Digital Lending"),
                new Stock("DLF.NS", "DLF Limited", "NSE", "Financial Services", "Real Estate Development"),
                new Stock("SIEMENS.NS", "Siemens Limited", "NSE", "Industrials", "Electrical Equipment"),
                new Stock("TRENT.NS", "Trent Limited", "NSE", "Consumer Goods", "Retail / Apparel"),
                new Stock("GAIL.NS", "GAIL (India) Limited", "NSE", "Utilities", "Natural Gas Transmission"),
                new Stock("PNB.NS", "Punjab National Bank", "NSE", "Financial Services", "Banking"),
                new Stock("IRFC.NS", "Indian Railway Finance Corporation Limited", "NSE", "Financial Services", "Railway Infrastructure Finance"),
                new Stock("ZOMATO.NS", "Zomato Limited", "NSE", "Consumer Goods", "Online Food Delivery"),
                new Stock("UNIONBANK.NS", "Union Bank of India", "NSE", "Financial Services", "Banking"),
                new Stock("RECLTD.NS", "REC Limited", "NSE", "Financial Services", "Power Sector Finance"),
                new Stock("PFC.NS", "Power Finance Corporation Limited", "NSE", "Financial Services", "Power Sector Finance"),
                new Stock("CANBK.NS", "Canara Bank", "NSE", "Financial Services", "Banking"),
                new Stock("BANKBARODA.NS", "Bank of Baroda", "NSE", "Financial Services", "Banking"),
                new Stock("IOC.NS", "Indian Oil Corporation Limited", "NSE", "Energy", "Oil & Gas Refining"),
                new Stock("VBL.NS", "Varun Beverages Limited", "NSE", "Consumer Goods", "Beverages"),
                new Stock("PIDILITIND.NS", "Pidilite Industries Limited", "NSE", "Basic Materials", "Adhesives & Chemicals"),
                new Stock("CHOLAFIN.NS", "Cholamandalam Investment and Finance Company Limited", "NSE", "Financial Services", "NBFC / Auto Loans"),
                new Stock("HAVELLS.NS", "Havells India Limited", "NSE", "Consumer Goods", "Electrical Appliances"),
                new Stock("HDFCAMC.NS", "HDFC Asset Management Company Limited", "NSE", "Financial Services", "Mutual Fund Management"),
                new Stock("SHREECEM.NS", "Shree Cement Limited", "NSE", "Basic Materials", "Cement"),
                new Stock("SRF.NS", "SRF Limited", "NSE", "Basic Materials", "Chemicals & Polymers"),
                new Stock("MARICO.NS", "Marico Limited", "NSE", "Consumer Goods", "FMCG / Hair Care"),
                new Stock("AMBUJACEM.NS", "Ambuja Cements Limited", "NSE", "Basic Materials", "Cement"),
                new Stock("GODREJCP.NS", "Godrej Consumer Products Limited", "NSE", "Consumer Goods", "FMCG / Personal Care"),
                new Stock("DABUR.NS", "Dabur India Limited", "NSE", "Consumer Goods", "FMCG / Ayurvedic Products"),
                new Stock("COLPAL.NS", "Colgate-Palmolive (India) Limited", "NSE", "Consumer Goods", "FMCG / Oral Care"),
                new Stock("BERGEPAINT.NS", "Berger Paints India Limited", "NSE", "Consumer Goods", "Paints"),
                new Stock("MUTHOOTFIN.NS", "Muthoot Finance Limited", "NSE", "Financial Services", "NBFC / Gold Loans"),
                new Stock("UBL.NS", "United Breweries Limited", "NSE", "Consumer Goods", "Beverages / Alcohol"),
                new Stock("MCDOWELL-N.NS", "United Spirits Limited", "NSE", "Consumer Goods", "Beverages / Alcohol"),
                new Stock("BOSCHLTD.NS", "Bosch Limited", "NSE", "Automotive", "Auto Parts"),
                new Stock("PERSISTENT.NS", "Persistent Systems Limited", "NSE", "Technology", "IT Services"),
                new Stock("ACC.NS", "ACC Limited", "NSE", "Basic Materials", "Cement"),
                new Stock("NYKAA.NS", "FSN E-Commerce Ventures Limited", "NSE", "Consumer Goods", "E-Retail / Beauty & Fashion"),
                new Stock("PAYTM.NS", "One 97 Communications Limited", "NSE", "Financial Services", "Fintech / Payments"),
                new Stock("TATACOMM.NS", "Tata Communications Limited", "NSE", "Telecommunication", "Telecom Services"),
                new Stock("OBEROIRLTY.NS", "Oberoi Realty Limited", "NSE", "Financial Services", "Real Estate Development"),
                new Stock("AUROPHARMA.NS", "Aurobindo Pharma Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("LUPIN.NS", "Lupin Limited", "NSE", "Healthcare", "Pharmaceuticals"),
                new Stock("TATAELXSI.NS", "Tata Elxsi Limited", "NSE", "Technology", "Design & IT services"),
                new Stock("BANDHANBNK.NS", "Bandhan Bank Limited", "NSE", "Financial Services", "Banking"),
                new Stock("SAIL.NS", "Steel Authority of India Limited", "NSE", "Basic Materials", "Steel & Iron"),
                new Stock("TATACHEM.NS", "Tata Chemicals Limited", "NSE", "Basic Materials", "Inorganic Chemicals"),
                new Stock("CONCOR.NS", "Container Corporation of India Limited", "NSE", "Industrials", "Logistics & Transport"),
                new Stock("NMDC.NS", "NMDC Limited", "NSE", "Basic Materials", "Iron Ore Mining"),
                new Stock("BHEL.NS", "Bharat Heavy Electricals Limited", "NSE", "Industrials", "Heavy Power Equipment"),
                new Stock("GMRINFRA.NS", "GMR Airports Infrastructure Limited", "NSE", "Industrials", "Airport Infrastructure"),
                new Stock("ABCAPITAL.NS", "Aditya Birla Capital Limited", "NSE", "Financial Services", "Holding Company / NBFC"),
                new Stock("JUBLFOOD.NS", "Jubilant FoodWorks Limited", "NSE", "Consumer Goods", "QSR / Restaurants")
            );

            stockRepository.saveAll(defaultStocks);
            logger.info("Successfully seeded {} NIFTY 100 stocks.", defaultStocks.size());
            seeded = true;
        } else {
            logger.info("Stocks already present in the database. Skipping seeding.");
        }

        if (seeded || stockPriceRepository.count() == 0) {
            // Run initial data sync asynchronously in the background so it doesn't block startup
            CompletableFuture.runAsync(() -> {
                try {
                    logger.info("Starting initial stock data sync from Yahoo Finance...");
                    yahooFinanceService.syncAllActiveStocks();
                    logger.info("Initial stock data sync completed.");
                } catch (Exception e) {
                    logger.error("Error during initial stock sync: ", e);
                }
            });
        } else {
            logger.info("Stock prices already present in the database. Skipping initial sync.");
        }
    }
}
