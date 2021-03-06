//+------------------------------------------------------------------+
//|                                               SignalCrossEMA.mqh |
//|                      Copyright � 2010, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//|                                              Revision 2010.10.12 |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>

// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Signals based on crossover of two EMA                      |
//| Type=Signal                                                      |
//| Name=CrossEMA                                                    |
//| Class=CSignalCrossEMA                                            |
//| Page=                                                            |
//| Parameter=FastPeriod,int,12                                      |
//| Parameter=SlowPeriod,int,24                                      |
//+------------------------------------------------------------------+
// wizard description end

//+------------------------------------------------------------------+
//| Class CSignalCrossEMA.                                           |
//| Appointment: Class trading signals cross two EMA.                |
//|              Derives from class CExpertSignal.                   |
//+------------------------------------------------------------------+
class CSignalCrossEMA : public CExpertSignal
{
protected:
    CiMA             *m_FastEMA;
    CiMA             *m_SlowEMA;
    //--- input parameters
    int               m_fast_period;
    int               m_slow_period;
    float             m_max_previous_value;
    int               m_retracement_threshold;
    float             m_allowed_retracement_percent;
    bool              m_we_win;
    bool              m_we_started_retracing;
    int               m_min_win;
    bool              m_we_dont_want_to_loose_money;
    bool              m_enable_never_loose_money;

public:
                      CSignalCrossEMA();
                     ~CSignalCrossEMA();
    //--- methods initialize protected data
    void              FastPeriod(int period) { m_fast_period = period;                }
    void              SlowPeriod(int period) { m_slow_period = period;                }
    void              RetracementThreshold(int threshold) { m_retracement_threshold=threshold; }
    void              AllowedRetracement(float allowed_retracement) { m_allowed_retracement_percent=allowed_retracement; }
    void              MinWin(int min_win) { m_min_win=min_win; }
    virtual bool      InitIndicators(CIndicators* indicators);
    virtual bool      ValidationSettings();
    //---
    virtual bool      CheckOpenLong(double& price, double& sl, double& tp, datetime& expiration);
    virtual bool      CheckCloseLong(double& price);
    virtual bool      CheckOpenShort(double& price, double& sl, double& tp, datetime& expiration);
    virtual bool      CheckCloseShort(double& price);

protected:
    bool              InitFastEMA(CIndicators* indicators);
    bool              InitSlowEMA(CIndicators* indicators);
    //---
    double            FastEMA(int ind)       { return(m_FastEMA.Main(ind));             }
    double            SlowEMA(int ind)       { return(m_SlowEMA.Main(ind));             }
    double            StateFastEMA(int ind)  { return(FastEMA(ind) - FastEMA(ind + 1)); }
    double            StateSlowEMA(int ind)  { return(SlowEMA(ind) - SlowEMA(ind + 1)); }
    double            StateEMA(int ind)      { return(FastEMA(ind) - SlowEMA(ind));     }
};
  
//+------------------------------------------------------------------+
//| Constructor CSignalCrossEMA.                                     |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSignalCrossEMA::CSignalCrossEMA()
{
    //--- initialize protected data
    m_FastEMA     = NULL;
    m_SlowEMA     = NULL;
    //--- set default inputs
    m_fast_period = 12;
    m_slow_period = 24;
    m_max_previous_value = 0;
    m_retracement_threshold = 70;
    m_allowed_retracement_percent = 70;
    m_we_win = false;
    m_we_started_retracing = false;
    m_we_dont_want_to_loose_money = false;
    m_enable_never_loose_money = false;
}

//+------------------------------------------------------------------+
//| Destructor CSignalCrossEMA.                                      |
//| INPUT:  no.                                                      |
//| OUTPUT: no.                                                      |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
void CSignalCrossEMA::~CSignalCrossEMA()
{
    //---
}

//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//| INPUT:  no.                                                      |
//| OUTPUT: true-if settings are correct, false otherwise.           |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::ValidationSettings()
{
    if(m_fast_period >= m_slow_period)
    {
        printf(__FUNCTION__ + ": period of slow EMA must be greater than period of fast EMA");
        return(false);
    }
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create indicators.                                               |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitIndicators(CIndicators* indicators)
{
    //--- check
    if (indicators == NULL)        
        return(false);
        
    //--- create and initialize fast EMA indicator
    if (!InitFastEMA(indicators))
        return(false);
        
    //--- create and initialize slow EMA indicator
    if (!InitSlowEMA(indicators))
        return(false);
        
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create fast EMA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitFastEMA(CIndicators* indicators)
{
    //--- create fast EMA indicator
    if (m_FastEMA == NULL)
    {
        if ((m_FastEMA=new CiMA) == NULL)
        {
            printf(__FUNCTION__ + ": error creating object");
           return(false);
        }
    }
       
    //--- add fast EMA indicator to collection
    if (!indicators.Add(m_FastEMA))
    {
        printf(__FUNCTION__ + ": error adding object");
        delete m_FastEMA;
        return(false);
    }
    
    //--- initialize fast EMA indicator
    if (!m_FastEMA.Create(m_symbol.Name(), m_period, m_fast_period, 0, MODE_EMA, PRICE_CLOSE))
    {
        printf(__FUNCTION__ + ": error initializing object");
        return(false);
    }
    
    m_FastEMA.BufferResize(1000);
    
    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Create slow EMA indicators.                                      |
//| INPUT:  indicators -pointer of indicator collection.             |
//| OUTPUT: true-if successful, false otherwise.                     |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::InitSlowEMA(CIndicators* indicators)
{
    //--- create slow EMA indicator
    if (m_SlowEMA == NULL)
        if((m_SlowEMA = new CiMA) == NULL)
        {
            printf(__FUNCTION__+": error creating object");
            return(false);
        }
        
    //--- add slow EMA indicator to collection
    if (!indicators.Add(m_SlowEMA))
    {
         printf(__FUNCTION__ + ": error adding object");
         delete m_SlowEMA;
         return(false);
    }

    //--- initialize slow EMA indicator
    if (!m_SlowEMA.Create(m_symbol.Name(), m_period, m_slow_period, 0, MODE_EMA, PRICE_CLOSE))
    {
         printf(__FUNCTION__ + ": error initializing object");
         return(false);
    }
    
    m_SlowEMA.BufferResize(1000);

    //--- ok
    return(true);
}

//+------------------------------------------------------------------+
//| Check conditions for long position open.                         |
//| INPUT:  price      - reference for price,                         |
//|         sl         - reference for stop loss,                     |
//|         tp         - reference for take profit,                   |
//|         expiration - reference for expiration.                    |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckOpenLong(double& price, double& sl, 
                                    double& tp, datetime& expiration)
{   
    if(!(StateEMA(2) < 0 && StateEMA(1) > 0))
        return(false);
        
    //---
    price = 0.0;
    sl    = m_symbol.Ask() - m_stop_level * m_adjusted_point;
    tp    = 0.0;
     
    // if position opened, maybe we should not open a new one
    printf("Opening Long Position because slow and fast EMA crossed");
    printf("ask: " +  m_symbol.Ask() + " stop level:" + m_stop_level + "sl:" + sl + "adjusted point: " + m_adjusted_point);   //---
    m_base_price = m_symbol.Ask();
    m_we_win = false;
    m_we_started_retracing = false;
    m_max_previous_value = 0;
    m_we_dont_want_to_loose_money = false;
    
    return(true);
}

//+------------------------------------------------------------------+
//| Check conditions for long position close.                        |
//| INPUT:  price - reference for price.                              |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckCloseLong(double& price)
{
    if (m_max_previous_value < m_symbol.Bid())
        m_max_previous_value = m_symbol.Bid();

    float diff = m_symbol.Bid() - m_base_price;
    printf(__FUNCTION__ + " m_max_previous_value = " + m_max_previous_value + 
           " bid " + m_symbol.Bid() + " base price " + m_base_price +
           " diff " + diff + " retracement threshold " + (m_retracement_threshold * m_adjusted_point));
    if (diff < 0)
    {
        printf(__FUNCTION__ + " we lose money (" + diff + " points)!");
    }    
    else if (diff == 0)
    {
        printf(__FUNCTION__ + " we are flat");
        if (m_enable_never_loose_money && m_we_dont_want_to_loose_money)
        {
            printf(__FUNCTION__ + " we won money but now we are flat. Closing");
            price = 0;
            return true;
        }
    }
    else
    {
        printf(__FUNCTION__ + " we are winning money (" + diff + " points)! m_symbol.Bid() = " + m_symbol.Ask());
        m_we_win = true;
        if (diff > 1.0)
        {
            m_we_dont_want_to_loose_money = true;
        }
        if (diff >= m_retracement_threshold * m_adjusted_point)
        {
            m_we_started_retracing = true;
            printf(__FUNCTION__ + " m_max_previous_value = " + (m_max_previous_value) + " base " + m_base_price); 
            printf(__FUNCTION__ + " allowed retracement " + int(m_allowed_retracement_percent) + "%%");
            float max_retracement = (m_max_previous_value - m_base_price) * (float(100.0 - m_allowed_retracement_percent)) / 100.0;
            printf(__FUNCTION__ + " a = " + (m_symbol.Bid() - m_base_price) + " / " + (m_max_previous_value - m_base_price));            
            float cur_retracement = ((m_symbol.Bid() - m_base_price) / (m_max_previous_value - m_base_price)) * 100.0;
            printf(__FUNCTION__ + " we started retracing! " + cur_retracement + "%%");
            max_retracement = float(int(max_retracement / m_adjusted_point)) * m_adjusted_point;
            printf(__FUNCTION__ + " max_retracement = " + max_retracement + " min price set to = " + (m_base_price + max_retracement));
            if (m_symbol.Bid() <= m_base_price + max_retracement)
            {
                printf(__FUNCTION__ + " max retracement reatched! closing");
                price = 0.0;
                return (true);
            }
        }
        else if (m_we_started_retracing)
        {
            printf(__FUNCTION__ + " we are going back in under retracement threshold " + 
                   (m_retracement_threshold * m_adjusted_point) + " diff is " + diff + ", min win " + (m_min_win * m_adjusted_point));
            if (diff <= m_min_win * m_adjusted_point)
            {
                printf(__FUNCTION__ + "no lose money principle: closing ! min win" + m_min_win);
                price = 0.0;
                return(true);
            }
        }
    }
    
    if(!(StateEMA(2) > 0 && StateEMA(1) < 0))
        return(false);

    //---
    printf("Close Long poisition, MME crossed!");
    price = 0.0;
    //---

    return(true);
}

//+------------------------------------------------------------------+
//| Check conditions for short position open.                        |
//| INPUT:  price      - reference for price,                         |
//|         sl         - reference for stop loss,                     |
//|         tp         - reference for take profit,                   |
//|         expiration - reference for expiration.                    |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckOpenShort(double& price, double& sl, 
                                     double& tp, datetime& expiration)
{
    if(!(StateEMA(2) > 0 && StateEMA(1) < 0))
        return(false);
      
    //---
    price = 0.0;
    sl    = m_symbol.Bid() + m_stop_level * m_adjusted_point;
    tp    = 0.0;
    printf("Opening Short Position because slow and fast EMA crossed");
    printf("bid: " +  m_symbol.Bid() + " stop level:" + m_stop_level +
           " sl:" + sl + " adjusted point: " + m_adjusted_point);
    m_base_price = m_symbol.Bid();
    m_we_win = false;
    m_we_started_retracing = false;
    m_max_previous_value = 999999;
    m_we_dont_want_to_loose_money = false;
    
    //---
   
    return(true);
}
//+------------------------------------------------------------------+
//| Check conditions for short position close.                       |
//| INPUT:  price - reference for price.                              |
//| OUTPUT: true-if condition performed, false otherwise.            |
//| REMARK: no.                                                      |
//+------------------------------------------------------------------+
bool CSignalCrossEMA::CheckCloseShort(double& price)
{
    if (m_max_previous_value > m_symbol.Ask())
        m_max_previous_value = m_symbol.Ask();
        
    float diff = m_base_price - m_symbol.Ask();
    printf(__FUNCTION__ + " m_max_previous_value = " + 
           m_max_previous_value + " ask " + m_symbol.Ask() + 
           " base price " + m_base_price + " diff = " + diff);
    if (diff < 0)
    {
        printf(__FUNCTION__ + " we lose money ! (" + diff + "points)");
    }
    else if (diff == 0)
    {
        printf(__FUNCTION__ + " we are flat");
        if (m_enable_never_loose_money && m_we_dont_want_to_loose_money)
        {
            printf(__FUNCTION__ + " we won money but now we are flat. Closing");
            price = 0;
            return true;
        }
    }
    else
    {
        printf(__FUNCTION__ + " we are winning money (" + diff + " points)!");
        m_we_win = true;
        if (diff > 1.0)
        {
            m_we_dont_want_to_loose_money = true;
        }
        if (diff >= m_retracement_threshold * m_adjusted_point)
        {
            m_we_started_retracing = true;
            m_we_started_retracing = true;
            printf(__FUNCTION__ + " allowed retracement " + int(m_allowed_retracement_percent) + "%%");
            float max_retracement = -(m_max_previous_value - m_base_price) * (float(100.0 - m_allowed_retracement_percent)) / 100.0;
            printf(__FUNCTION__ + " a = " + (m_symbol.Ask() - m_base_price) + " / " + (m_max_previous_value - m_base_price));            
            float cur_retracement = ((m_symbol.Ask() - m_base_price) / (m_max_previous_value - m_base_price)) * 100.0;
            printf(__FUNCTION__ + " we started retracing! " + cur_retracement + "%%");
            max_retracement = float(int(max_retracement / m_adjusted_point)) * m_adjusted_point;
            printf(__FUNCTION__ + " max_retracement = " + max_retracement + " min price set to = " + (m_base_price + max_retracement));
            if (m_symbol.Ask() >= (m_base_price - max_retracement))
            {
                printf(__FUNCTION__ + " max retracement reatched! closing");
                price = 0.0;
                return (true);
            }
        }
        else if (m_we_started_retracing)
        {
            printf(__FUNCTION__ + " we are under retracement threshold " + m_retracement_threshold * m_adjusted_point);
            if (diff <= m_min_win * m_adjusted_point)
            {
                printf(__FUNCTION__ + "no lose money principle: closing ! min win" + m_min_win);
                price = 0.0;
                return(true);
            }
        }
    }    
    if(!(StateEMA(2) < 0 && StateEMA(1) > 0))
        return(false);
        
    //---
    price=0.0;
    //---
    return(true);
}
//+------------------------------------------------------------------+
