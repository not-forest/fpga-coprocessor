--Legal Notice: (C)2025 Altera Corporation. All rights reserved.  Your
--use of Altera Corporation's design tools, logic functions and other
--software and tools, and its AMPP partner logic functions, and any
--output files any of the foregoing (including device programming or
--simulation files), and any associated documentation or information are
--expressly subject to the terms and conditions of the Altera Program
--License Subscription Agreement or other applicable license agreement,
--including, without limitation, that your use is for the sole purpose
--of programming logic devices manufactured by Altera and sold by Altera
--or its authorized distributors.  Please refer to the applicable
--agreement for further details.


-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--Register map:
--addr      register      type
--0         read data     r
--1         write data    w
--2         status        r/w
--3         control       r/w
--6         end-of-packet-value r/w
--INPUT_CLOCK: 100000000
--ISMASTER: 0
--DATABITS: 8
--TARGETCLOCK: 128000
--NUMSLAVES: 1
--CPOL: 1
--CPHA: 1
--LSBFIRST: 0
--EXTRADELAY: 0
--TARGETSSDELAY: 0
--ds_data_wr_strobe is generated for slave mode.

entity coproc_soft_cpu_SPI_0 is 
        port (
              -- inputs:
                 signal MOSI : IN STD_LOGIC;
                 signal SCLK : IN STD_LOGIC;
                 signal SS_n : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal data_from_cpu : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal mem_addr : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
                 signal read_n : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal spi_select : IN STD_LOGIC;
                 signal write_n : IN STD_LOGIC;

              -- outputs:
                 signal MISO : OUT STD_LOGIC;
                 signal data_to_cpu : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
                 signal dataavailable : OUT STD_LOGIC;
                 signal endofpacket : OUT STD_LOGIC;
                 signal irq : OUT STD_LOGIC;
                 signal readyfordata : OUT STD_LOGIC
              );
end entity coproc_soft_cpu_SPI_0;


architecture europa of coproc_soft_cpu_SPI_0 is
  component altera_std_synchronizer is
GENERIC (
      depth : NATURAL
      );
    PORT (
    signal dout : OUT STD_LOGIC;
        signal clk : IN STD_LOGIC;
        signal din : IN STD_LOGIC;
        signal reset_n : IN STD_LOGIC
      );
  end component altera_std_synchronizer;
                signal E :  STD_LOGIC;
                signal EOP :  STD_LOGIC;
                signal MOSI_reg :  STD_LOGIC;
                signal ROE :  STD_LOGIC;
                signal RRDY :  STD_LOGIC;
                signal TMT :  STD_LOGIC;
                signal TOE :  STD_LOGIC;
                signal TRDY :  STD_LOGIC;
                signal control_wr_strobe :  STD_LOGIC;
                signal d1_tx_holding_emptied :  STD_LOGIC;
                signal data_rd_strobe :  STD_LOGIC;
                signal data_wr_strobe :  STD_LOGIC;
                signal ds1_SCLK :  STD_LOGIC;
                signal ds1_SCLK_n :  STD_LOGIC;
                signal ds1_SS_n :  STD_LOGIC;
                signal ds1_SS_nn :  STD_LOGIC;
                signal ds2_SCLK :  STD_LOGIC;
                signal ds2_SS_n :  STD_LOGIC;
                signal ds3_SS_n :  STD_LOGIC;
                signal ds_MOSI :  STD_LOGIC;
                signal ds_data_wr_strobe :  STD_LOGIC;
                signal endofpacketvalue_reg :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal endofpacketvalue_wr_strobe :  STD_LOGIC;
                signal forced_shift :  STD_LOGIC;
                signal iEOP_reg :  STD_LOGIC;
                signal iE_reg :  STD_LOGIC;
                signal iROE_reg :  STD_LOGIC;
                signal iRRDY_reg :  STD_LOGIC;
                signal iTMT_reg :  STD_LOGIC;
                signal iTOE_reg :  STD_LOGIC;
                signal iTRDY_reg :  STD_LOGIC;
                signal irq_reg :  STD_LOGIC;
                signal p1_data_rd_strobe :  STD_LOGIC;
                signal p1_data_to_cpu :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal p1_data_wr_strobe :  STD_LOGIC;
                signal p1_rd_strobe :  STD_LOGIC;
                signal p1_wr_strobe :  STD_LOGIC;
                signal rd_strobe :  STD_LOGIC;
                signal resetShiftSample :  STD_LOGIC;
                signal rx_holding_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal sample_clock :  STD_LOGIC;
                signal shiftStateZero :  STD_LOGIC;
                signal shift_clock :  STD_LOGIC;
                signal shift_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal spi_control :  STD_LOGIC_VECTOR (10 DOWNTO 0);
                signal spi_status :  STD_LOGIC_VECTOR (10 DOWNTO 0);
                signal state :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal status_wr_strobe :  STD_LOGIC;
                signal transactionEnded :  STD_LOGIC;
                signal tx_holding_emptied :  STD_LOGIC;
                signal tx_holding_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal wr_strobe :  STD_LOGIC;

begin

  --spi_control_port, which is an e_avalon_slave
  p1_rd_strobe <= (NOT rd_strobe AND spi_select) AND NOT read_n;
  -- Read is a two-cycle event.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      rd_strobe <= std_logic'('0');
    elsif clk'event and clk = '1' then
      rd_strobe <= p1_rd_strobe;
    end if;

  end process;

  p1_data_rd_strobe <= p1_rd_strobe AND to_std_logic((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000000"))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_rd_strobe <= std_logic'('0');
    elsif clk'event and clk = '1' then
      data_rd_strobe <= p1_data_rd_strobe;
    end if;

  end process;

  p1_wr_strobe <= (NOT wr_strobe AND spi_select) AND NOT write_n;
  -- Write is a two-cycle event.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      wr_strobe <= std_logic'('0');
    elsif clk'event and clk = '1' then
      wr_strobe <= p1_wr_strobe;
    end if;

  end process;

  p1_data_wr_strobe <= p1_wr_strobe AND to_std_logic((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000001"))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_wr_strobe <= std_logic'('0');
    elsif clk'event and clk = '1' then
      data_wr_strobe <= p1_data_wr_strobe;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      ds_data_wr_strobe <= std_logic'('0');
    elsif clk'event and clk = '1' then
      ds_data_wr_strobe <= data_wr_strobe;
    end if;

  end process;

  control_wr_strobe <= wr_strobe AND to_std_logic((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000011"))));
  status_wr_strobe <= wr_strobe AND to_std_logic((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000010"))));
  endofpacketvalue_wr_strobe <= wr_strobe AND to_std_logic((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000110"))));
  TMT <= SS_n AND TRDY;
  E <= ROE OR TOE;
  spi_status <= std_logic_vector'("0") & (Std_Logic_Vector'(A_ToStdLogicVector(EOP) & A_ToStdLogicVector(E) & A_ToStdLogicVector(RRDY) & A_ToStdLogicVector(TRDY) & A_ToStdLogicVector(TMT) & A_ToStdLogicVector(TOE) & A_ToStdLogicVector(ROE) & std_logic_vector'("000")));
  -- Streaming data ready for pickup.
  dataavailable <= RRDY;
  -- Ready to accept streaming data.
  readyfordata <= TRDY;
  -- Endofpacket condition detected.
  endofpacket <= EOP;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      iEOP_reg <= std_logic'('0');
      iE_reg <= std_logic'('0');
      iRRDY_reg <= std_logic'('0');
      iTRDY_reg <= std_logic'('0');
      iTMT_reg <= std_logic'('0');
      iTOE_reg <= std_logic'('0');
      iROE_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(control_wr_strobe) = '1' then 
        iEOP_reg <= data_from_cpu(9);
        iE_reg <= data_from_cpu(8);
        iRRDY_reg <= data_from_cpu(7);
        iTRDY_reg <= data_from_cpu(6);
        iTMT_reg <= data_from_cpu(5);
        iTOE_reg <= data_from_cpu(4);
        iROE_reg <= data_from_cpu(3);
      end if;
    end if;

  end process;

  spi_control <= std_logic_vector'("0") & (Std_Logic_Vector'(A_ToStdLogicVector(iEOP_reg) & A_ToStdLogicVector(iE_reg) & A_ToStdLogicVector(iRRDY_reg) & A_ToStdLogicVector(iTRDY_reg) & A_ToStdLogicVector(std_logic'('0')) & A_ToStdLogicVector(iTOE_reg) & A_ToStdLogicVector(iROE_reg) & std_logic_vector'("000")));
  -- IRQ output.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      irq_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      irq_reg <= ((((((EOP AND iEOP_reg)) OR ((((TOE OR ROE)) AND iE_reg))) OR ((RRDY AND iRRDY_reg))) OR ((TRDY AND iTRDY_reg))) OR ((TOE AND iTOE_reg))) OR ((ROE AND iROE_reg));
    end if;

  end process;

  irq <= irq_reg;
  -- End-of-packet value register.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      endofpacketvalue_reg <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(endofpacketvalue_wr_strobe) = '1' then 
        endofpacketvalue_reg <= data_from_cpu;
      end if;
    end if;

  end process;

  p1_data_to_cpu <= A_WE_StdLogicVector((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000010"))), (std_logic_vector'("00000") & (spi_status)), A_WE_StdLogicVector((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000011"))), (std_logic_vector'("00000") & (spi_control)), A_WE_StdLogicVector((((std_logic_vector'("00000000000000000000000000000") & (mem_addr)) = std_logic_vector'("00000000000000000000000000000110"))), endofpacketvalue_reg, (std_logic_vector'("00000000") & (rx_holding_reg)))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      data_to_cpu <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      -- Data to cpu.
      data_to_cpu <= p1_data_to_cpu;
    end if;

  end process;

  forced_shift <= ds2_SS_n AND NOT ds3_SS_n;
  the_altera_std_synchronizer : altera_std_synchronizer
    generic map(
      depth => 2
    )
    port map(
            clk => clk,
            din => NOT SS_n,
            dout => ds1_SS_nn,
            reset_n => reset_n
    );

  ds1_SS_n <= NOT ds1_SS_nn;
  -- System clock domain events.
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      ds2_SS_n <= std_logic'('1');
      ds3_SS_n <= std_logic'('1');
      transactionEnded <= std_logic'('0');
      EOP <= std_logic'('0');
      RRDY <= std_logic'('0');
      TRDY <= std_logic'('1');
      TOE <= std_logic'('0');
      ROE <= std_logic'('0');
      tx_holding_reg <= std_logic_vector'("00000000");
      rx_holding_reg <= std_logic_vector'("00000000");
      d1_tx_holding_emptied <= std_logic'('0');
    elsif clk'event and clk = '1' then
      ds2_SS_n <= ds1_SS_n;
      ds3_SS_n <= ds2_SS_n;
      transactionEnded <= forced_shift;
      d1_tx_holding_emptied <= tx_holding_emptied;
      if std_logic'((tx_holding_emptied AND NOT d1_tx_holding_emptied)) = '1' then 
        -- ds_data_wr_strobe addresses events if data_wr_strobe happens at the same edge as shift_clock. In this case, keep TRDY at 0.
        --As long as data_wr_strobe occurs, always set TRDY to 0
        if std_logic'((ds_data_wr_strobe OR data_wr_strobe)) = '1' then 
          TRDY <= std_logic'('0');
        else
          TRDY <= std_logic'('1');
        end if;
      elsif std_logic'(data_wr_strobe) = '1' then 
        TRDY <= std_logic'('0');
      end if;
      -- EOP must be updated by the last (2nd) cycle of access.
      if std_logic'((((p1_data_rd_strobe AND to_std_logic((((std_logic_vector'("00000000") & (rx_holding_reg)) = endofpacketvalue_reg))))) OR ((p1_data_wr_strobe AND to_std_logic((((std_logic_vector'("00000000") & (data_from_cpu(7 DOWNTO 0))) = endofpacketvalue_reg))))))) = '1' then 
        EOP <= std_logic'('1');
      end if;
      if std_logic'(forced_shift) = '1' then 
        if std_logic'(RRDY) = '1' then 
          ROE <= std_logic'('1');
        else
          rx_holding_reg <= shift_reg;
        end if;
        RRDY <= std_logic'('1');
      end if;
      -- On data read, clear the RRDY bit. 
      if std_logic'(data_rd_strobe) = '1' then 
        RRDY <= std_logic'('0');
      end if;
      -- On status write, clear all status bits (ignore the data).
      if std_logic'(status_wr_strobe) = '1' then 
        EOP <= std_logic'('0');
        RRDY <= std_logic'('0');
        ROE <= std_logic'('0');
        TOE <= std_logic'('0');
      end if;
      -- On data write, load the transmit holding register and prepare to execute.
      --Safety feature: if tx_holding_reg is already occupied, ignore this write, and generate
      --the write-overrun error.
      if std_logic'(data_wr_strobe) = '1' then 
        if std_logic'(TRDY) = '1' then 
          tx_holding_reg <= data_from_cpu (7 DOWNTO 0);
        end if;
        if std_logic'(NOT TRDY) = '1' then 
          TOE <= std_logic'('1');
        end if;
      end if;
    end if;

  end process;

  resetShiftSample <= NOT reset_n OR transactionEnded;
  MISO <= NOT SS_n AND shift_reg(7);
  the_altera_std_synchronizer1 : altera_std_synchronizer
    generic map(
      depth => 2
    )
    port map(
            clk => clk,
            din => NOT SCLK,
            dout => ds1_SCLK_n,
            reset_n => reset_n
    );

  ds1_SCLK <= NOT ds1_SCLK_n;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      ds2_SCLK <= std_logic'('1');
    elsif clk'event and clk = '1' then
      ds2_SCLK <= ds1_SCLK;
    end if;

  end process;

  shift_clock <= (NOT ((NOT ds1_SS_n AND ds1_SCLK))) AND NOT (NOT ((NOT ds2_SS_n AND ds2_SCLK)));
  sample_clock <= ((NOT ds1_SS_n AND ds1_SCLK)) AND NOT ((NOT ds2_SS_n AND ds2_SCLK));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      state <= A_EXT (A_WE_StdLogicVector((std_logic'(resetShiftSample) = '1'), std_logic_vector'("000000000000000000000000000000000"), A_WE_StdLogicVector((std_logic'(((sample_clock AND to_std_logic((((std_logic_vector'("0000000000000000000000000000") & (state)) /= std_logic_vector'("00000000000000000000000000001000"))))))) = '1'), (((std_logic_vector'("00000000000000000000000000000") & (state)) + std_logic_vector'("000000000000000000000000000000001"))), (std_logic_vector'("00000000000000000000000000000") & (state)))), 4);
    end if;

  end process;

  the_altera_std_synchronizer2 : altera_std_synchronizer
    generic map(
      depth => 2
    )
    port map(
            clk => clk,
            din => MOSI,
            dout => ds_MOSI,
            reset_n => reset_n
    );

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      MOSI_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      MOSI_reg <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(resetShiftSample) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(A_WE_StdLogic((std_logic'(sample_clock) = '1'), ds_MOSI, MOSI_reg))))));
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      shift_reg <= std_logic_vector'("00000000");
    elsif clk'event and clk = '1' then
      shift_reg <= A_EXT (A_WE_StdLogicVector((std_logic'(resetShiftSample) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("000000000000000000000000") & (A_WE_StdLogicVector((std_logic'(shift_clock) = '1'), (A_WE_StdLogicVector((std_logic'(shiftStateZero) = '1'), tx_holding_reg, Std_Logic_Vector'(shift_reg(6 DOWNTO 0) & A_ToStdLogicVector(MOSI_reg)))), shift_reg)))), 8);
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      shiftStateZero <= std_logic'('1');
    elsif clk'event and clk = '1' then
      shiftStateZero <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(resetShiftSample) = '1'), std_logic_vector'("00000000000000000000000000000001"), A_WE_StdLogicVector((std_logic'(shift_clock) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(shiftStateZero))))));
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      tx_holding_emptied <= std_logic'('0');
    elsif clk'event and clk = '1' then
      tx_holding_emptied <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(resetShiftSample) = '1'), std_logic_vector'("00000000000000000000000000000000"), A_WE_StdLogicVector((std_logic'(shift_clock) = '1'), (A_WE_StdLogicVector((std_logic'(shiftStateZero) = '1'), std_logic_vector'("00000000000000000000000000000001"), std_logic_vector'("00000000000000000000000000000000"))), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(tx_holding_emptied))))));
    end if;

  end process;


end europa;

