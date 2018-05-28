class Tag < ApplicationRecord
  belongs_to :trip

  NAMES = [
    'Adult Themes',
    'Adventure',
    'Culture and History',
    'Family or Friends',
    'Kid-Friendly',
    'Nature',
    'Party and Nightlife',
    'Relaxation',
    'Retirement',
    'Romance'
  ]

  NAMES_TO_ICONS =
    {
      'Adult Themes' => 'beer',
      'Adventure' => 'map-o',
      'Culture and History' => 'university',
      'Family or Friends' => 'group',
      'Kid-Friendly' => 'child',
      'Nature' => 'tree',
      'Party and Nightlife' => 'glass',
      'Relaxation' => 'bed',
      'Retirement' => 'trophy',
      'Romance' => 'heart'
    }
end
