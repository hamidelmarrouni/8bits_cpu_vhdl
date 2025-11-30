library ieee;
use ieee.std_logic_1164.all;

entity tb_cpu_full is
end entity;

architecture sim of tb_cpu_full is

    signal clk   : std_logic := '0';
    signal rst_n : std_logic := '0';
    constant T   : time := 10 ns;

begin
    ----------------------------------------------------------------
    -- Clock generator
    ----------------------------------------------------------------
    clk <= not clk after T/2;

    ----------------------------------------------------------------
    -- CPU under test
    ----------------------------------------------------------------
    uut : entity work.cpu_top
        port map(
            clk   => clk,
            rst_n => rst_n
        );

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    process
    begin
        -- Reset low
        rst_n <= '0';
        wait for 10*T;

        -- Release reset
        rst_n <= '1';

        -- Let CPU run
        wait for 5000 ns;

        -- Stop simulation
        assert false
            report "End of CPU full simulation"
            severity failure;
    end process;

end architecture;
