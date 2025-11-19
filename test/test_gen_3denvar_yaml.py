import argparse
import datetime as dt
import os
from wxflow import parse_j2yaml, cast_strdict_as_dtypedict, save_as_yaml
from wxflow import add_to_datetime, to_timedelta, to_datetime

my_dir = os.path.dirname(__file__)
rdas_dir = os.path.join(my_dir, '../')

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=str, help='Input YAML Template', required=True)
    parser.add_argument('-o', '--output', type=str, help='Output YAML File', required=True)
    args = parser.parse_args()

    os.environ['BERROR_YAML'] = os.path.join(rdas_dir, 'parm', 'atm', 'berror', 'staticb_identity.yaml')
    os.environ['OBS_LIST'] = os.path.join(rdas_dir, 'parm', 'atm', 'obs', 'lists', 'rdas_prototype.yaml')
    os.environ['OBS_YAML_DIR'] = os.path.join(rdas_dir, 'parm', 'atm', 'obs', 'config')

    # let us define a configuration dictionary, note this will be incomplete and an example
    config = {
        'ATM_WINDOW_BEGIN': to_datetime('2024-07-08T03:00:00Z'),
        'ATM_WINDOW_LENGTH': 'PT6H',
        'layout_x': 1,
        'layout_y': 1,
        'npx_ges': 661,
        'npy_ges': 661,
        'npz_ges': 81,
        'current_cycle': to_datetime('2024-07-08T06:00:00Z'),
        'npx_anl': 661,
        'npy_anl': 661,
        'npz_anl': 81,
        'DATA': os.path.join(os.path.dirname(args.output)),
        'GPREFIX': 'hafs.t03z.',
        'APREFIX': 'hafs.t06z.',
    }

    final_config = parse_j2yaml(args.input, config)
    save_as_yaml(final_config, args.output)
